docker run -ti --rm -v $('pwd'):/mnt/workspace \
       -v /etc/localtime:/etc/localtime:ro \
       -v ~/.ssh/id_rsa:${UHOME}/.ssh/id_rsa:ro \
       -v ~/.gnupg:${UHOME}/.gnupg \
       -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
       -v /tmp/.X11-unix:/tmp/.X11-unix \
       -v /etc/machine-id:/etc/machine-id:ro \
       -v ~/.emacs.d-docker/:/root/.emacs.d \
       -v $(pwd)/.spacemacs:/root/.spacemacs \
       -v $(pwd)/demo-projects/:/Projects \
       -v $(pwd)/local/share/fonts:/root/.local/share/fonts/ \
       -v ~/.m2/:/root/.m2 \
       -e DISPLAY=$DISPLAY \
       -e TZ=UA \
       yyoncho/lsp-emacs-docker emacs
