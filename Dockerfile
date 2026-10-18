# The dedicated server's image (DEC-0032 §1; TASK-9, criterion 15), from the probe's recipe
# (F-073; ../servidor-sonda): the Linux server build of export_presets.cfg on debian:trixie-slim,
# with tini as PID 1, a user without root and the port 7777/udp. tini only passes signals on and
# reaps zombies: Godot does not handle SIGTERM, so `docker stop` kills the server with 143
# (F-073 §2). The clean close is the stop file (DEC-0032 §2; rede.md §9):
#   docker exec CONTAINER touch /home/jogo/stop
# Export the server first (bash tools/export_builds.sh server): the .dockerignore sends only its
# build. tools/server_image_check.sh builds this image, checks it and removes it; it is never
# pushed.
FROM debian:trixie-slim

RUN apt-get update \
	&& apt-get install -y --no-install-recommends tini \
	&& rm -rf /var/lib/apt/lists/* \
	&& useradd --create-home --uid 10001 jogo

WORKDIR /home/jogo
# Owned by root: the server's user runs it and cannot change it. --chmod sets the executable bit
# whatever system exported the build.
COPY --chmod=0755 build/linux/jogo-acrobatico-servidor.x86_64 ./jogo-acrobatico-servidor.x86_64
USER jogo

EXPOSE 7777/udp
# The build is a dedicated server: it runs the server mode by itself, headless (rede.md §9). The
# stop file sits in the user's home, where it can write.
ENTRYPOINT ["/usr/bin/tini", "--", "./jogo-acrobatico-servidor.x86_64", "--headless", "--", "--stop-file=/home/jogo/stop"]
