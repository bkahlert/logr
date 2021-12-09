FROM asciinema/asciinema

# build time only options
ARG APP_USER=recordr
ARG APP_GROUP=$APP_USER
ARG APP_HOME="/home/$APP_USER"

# build and run time options
ARG TZ=UTC
ARG LANG=C.UTF-8
ARG PUID=1000
ARG PGID=1000

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
    dumb-init \
    expect \
    nodejs \
    npm \
    rsync \ \
 && rm -rf /tmp/* /var/lib/apt/list/* \
 && npm install -g svg-term-cli \
 && groupadd \
    --gid "$PGID" \
    "$APP_GROUP" \
 && useradd \
    --comment "app user" \
    --uid $PUID \
    --gid "$APP_GROUP" \
    --home "$APP_HOME" \
    --shell /bin/bash \
    "$APP_USER"

COPY --from=crazymax/yasu:1.17.0 / /
COPY recordr /usr/local/bin/
RUN mkdir -p "$APP_HOME" \
 && chown -R "$PUID:$PGID" "$APP_HOME" \
 && chmod -R 0700 "$APP_HOME" \
 && chmod +x /usr/local/bin/recordr

# && curl -LfsSo /usr/local/bin/logr.sh https://raw.githubusercontent.com/bkahlert/logr/master/logr.sh

ENV TZ="$TZ" \
    LANG="$LANG" \
    PUID="$PUID" \
    PGID="$PGID"

WORKDIR "$APP_HOME"
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/local/bin/recordr"]
