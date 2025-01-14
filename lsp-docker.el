;;; lsp-docker.el --- LSP Docker integration         -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Ivan Yonchovski

;; Author: Ivan Yonchovski <yyoncho@gmail.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:
(require 'lsp-mode)
(require 'dash)

(defun lsp--docker-uri->path (path-mappings docker-container-name uri)
  (let ((path (lsp--uri-to-path-1 uri)))
    (-if-let ((local . remote) (-first (-lambda ((_ . docker-path))
                                         (s-contains? docker-path path))
                                       path-mappings))
        (s-replace remote local path)
      (format "/docker:%s:%s" docker-container-name path))))

(defun lsp--docker-path->uri (path-mappings path)
  (lsp--path-to-uri-1
   (-if-let ((local . remote) (-first (-lambda ((local-path . _))
                                        (s-contains? local-path path))
                                      path-mappings))
       (s-replace local remote path)
     (user-error "The path %s is not under path mappings" path))))

(defun lsp-docker-launch-new-container (docker-container-name path-mappings docker-image-id server-command)
  (split-string
   (--doto (format "docker run --name %s --rm -i %s %s %s"
                   docker-container-name
                   (->> path-mappings
                        (-map (-lambda ((path . docker-path))
                                (format "-v %s:%s" path docker-path)))
                        (s-join " "))
                   docker-image-id
                   server-command))
   " "))

(defun lsp-docker-exec-in-container (docker-container-name path-mappings docker-image-id server-command)
  (split-string
   (format "docker exec -i %s %s" docker-container-name server-command)
   ))

(cl-defun lsp-docker-register-client (&key server-id
                                           docker-server-id
                                           path-mappings
                                           docker-image-id
                                           docker-container-name
                                           priority
                                           server-command
                                           launch-server-cmd-fn)

  (if-let ((client (copy-lsp--client (gethash server-id lsp-clients))))
      (progn
        (setf (lsp--client-server-id client) docker-server-id
              (lsp--client-uri->path-fn client) (-partial #'lsp--docker-uri->path
                                                          path-mappings
                                                          docker-container-name)
              (lsp--client-path->uri-fn client) (-partial #'lsp--docker-path->uri path-mappings)
              (lsp--client-new-connection client) (lsp-stdio-connection
                                                   (lambda ()
                                                     (funcall (or launch-server-cmd-fn #'lsp-docker-launch-new-container)
                                                              docker-container-name
                                                              path-mappings
                                                              docker-image-id
                                                              server-command)
                                                     ))
              (lsp--client-priority client) (or priority (lsp--client-priority client)))
        (lsp-register-client client))
    (user-error "No such client %s" server-id)))

(cl-defun lsp-docker-init-default-clients (&key
                                           path-mappings
                                           (docker-image-id "yyoncho/lsp-emacs-docker")
                                           (docker-container-name "lsp-container")
                                           (priority 10))
  (lsp-docker-register-client
   :server-id 'rls
   :priority priority
   :docker-server-id 'rls-docker
   :docker-image-id docker-image-id
   :docker-container-name docker-container-name
   :server-command "rls"
   :path-mappings path-mappings
   :launch-container-server #'lsp-docker-launch-new-container)

  (lsp-docker-register-client
   :server-id 'pyls
   :priority priority
   :docker-server-id 'pyls-docker
   :docker-image-id docker-image-id
   :docker-container-name docker-container-name
   :server-command "pyls"
   :path-mappings path-mappings
   :launch-container-server #'lsp-docker-launch-new-container))

(provide 'lsp-docker)
;;; lsp-docker.el ends here

;; Local Variables:
;; flycheck-disabled-checkers: (emacs-lisp-checkdoc)
;; End:
