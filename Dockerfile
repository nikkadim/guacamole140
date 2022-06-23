# Select BASE
# to fix CVE-2022-29885
FROM tomcat:9.0.64-jre8-openjdk-slim-buster

ARG APPLICATION="guacamole"
ARG BUILD_RFC3339="2022-06-22T11:00:00Z"
ARG REVISION="local"
ARG DESCRIPTION="Guacamole 1.4.0"
ARG PACKAGE="nikkadim/guacamole140"
ARG VERSION="1.4.0"
ARG TARGETPLATFORM
ARG DEBIAN_FRONTEND=noninteractive

#STOPSIGNAL SIGKILL


ENV \
      APPLICATION="${APPLICATION}" \
      BUILD_RFC3339="${BUILD_RFC3339}" \
      REVISION="${REVISION}" \
      DESCRIPTION="${DESCRIPTION}" \
      PACKAGE="${PACKAGE}" \
      VERSION="${VERSION}"

ENV \ 
GUAC_VER=1.4.0 \
GUACAMOLE_HOME=/app/guacamole \
PG_MAJOR=11 \
PGDATA=/config/postgres \
POSTGRES_USER=guacamole \
POSTGRES_DB=guacamole_db

#Set working DIR
WORKDIR ${GUACAMOLE_HOME}

# Look for debian testing packets
RUN echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" >> /etc/apt/sources.list

#Add essential packages
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y curl postgresql-${PG_MAJOR} ghostscript  net-tools 


# Apply the s6-overlay
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCH=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v6" ]; then ARCH=arm; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCH=armhf; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCH=aarch64; else ARCH=amd64; fi \
  && curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-${ARCH}.tar.gz" \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C / \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C /usr ./bin \
  && rm -rf s6-overlay-${ARCH}.tar.gz \
  && mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/lib \
    ${GUACAMOLE_HOME}/extensions

# Install dependencies
RUN apt-get update && apt-get -t buster-backports install -y \
    build-essential \
    libcairo2-dev libjpeg62-turbo-dev libpng-dev libtool-bin uuid-dev libossp-uuid-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
    freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev \
    libssl-dev libvorbis-dev libwebp-dev

# Install guacamole-server
#RUN curl -SLO "https://apache.org/dyn/closer.lua?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
RUN curl -SLo guacamole-server-${GUAC_VER}.tar.gz "http://apache.org/dyn/closer.lua/guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz?action=download" \
  && tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
  && cd guacamole-server-${GUAC_VER} \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && cd .. \
  && rm -rf guacamole-server-${GUAC_VER}.tar.gz guacamole-server-${GUAC_VER} \
  && ldconfig




# Install guacamole-client and postgres auth adapter
RUN set -x \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "https://apache.org/dyn/closer.lua/guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war?action=download" \
  && curl -SLo ${GUACAMOLE_HOME}/lib/postgresql-42.3.1.jar "https://jdbc.postgresql.org/download/postgresql-42.3.1.jar" \
  && curl -SLo guacamole-auth-jdbc-${GUAC_VER}.tar.gz "https://apache.org/dyn/closer.lua/guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz?action=download" \
  && tar -xzf guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
  && cp -R guacamole-auth-jdbc-${GUAC_VER}/postgresql/guacamole-auth-jdbc-postgresql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions/ \
  && cp -R guacamole-auth-jdbc-${GUAC_VER}/postgresql/schema ${GUACAMOLE_HOME}/ \
  && rm -rf guacamole-auth-jdbc-${GUAC_VER} guacamole-auth-jdbc-${GUAC_VER}.tar.gz

###############################################################################
################################# EXTENSIONS ##################################
###############################################################################

RUN mkdir ${GUACAMOLE_HOME}/extensions-available





# Purge BUild packages
RUN apt-get purge -y build-essential \
  && apt-get autoremove -y && apt-get autoclean \
  && rm -rf /var/lib/apt/lists/*

# Finishing Container configuration
ENV PATH=/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH
ENV GUACAMOLE_HOME=/config/guacamole

WORKDIR /config


EXPOSE 8080

COPY root /

ENTRYPOINT [ "/init" ]
