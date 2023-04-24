FROM debian:stable-slim
LABEL org.opencontainers.image.authors="https://github.com/belane" \
      org.opencontainers.image.description="BloodHound Docker Ready to Use" \
      org.opencontainers.image.source="https://github.com/belane/docker-bloodhound" \
      org.opencontainers.image.title="docker-bloodhound" \
      org.opencontainers.image.version="0.2.1"
ARG neo4j=4.4.19
ARG bloodhound=4.2.0

# Base packages
RUN apt-get update -qq &&\
    apt-get install --no-install-recommends -y -qq\
      wget \
      git \
      unzip \
      curl \
      gnupg \
      libgtk-3-0 \
      libgbm1 \
      libcanberra-gtk3-module \
      libx11-xcb1 \
      libva-glx2 \
      libgl1-mesa-glx \
      libgl1-mesa-dri \
      libgconf-2-4 \
      libasound2 \
      libxss1 \
      apt-transport-https \
      openjdk-11-jre

# Neo4j
RUN wget -nv -O - https://debian.neo4j.com/neotechnology.gpg.key | tee /etc/apt/trusted.gpg.d/neo4j.asc &&\
    echo 'deb https://debian.neo4j.com stable 4.4' | tee /etc/apt/sources.list.d/neo4j.list &&\
    apt-get update &&\
    apt-get install -y -qq neo4j=1:$neo4j

# BloodHound
RUN wget https://github.com/BloodHoundAD/BloodHound/releases/download/$bloodhound/BloodHound-linux-x64.zip -nv -P /tmp &&\
    unzip /tmp/BloodHound-linux-x64.zip -d /opt/ &&\
    mkdir /data &&\
    chmod +x /opt/BloodHound-linux-x64/BloodHound

# BloodHound Config
COPY config.json /root/.config/bloodhound/

# Custom Queries
RUN wget https://raw.githubusercontent.com/CompassSecurity/BloodHoundQueries/master/BloodHound_Custom_Queries/customqueries.json -nv -P /root/.config/bloodhound/

# Init Script
RUN echo '#!/usr/bin/env bash\n\
    neo4j-admin set-initial-password blood \n\
    service neo4j start\n\
    cp -n /opt/BloodHound-linux-x64/resources/app/Collectors/SharpHound.* /data\n\
    echo "\e[92m*** Log in with bolt://127.0.0.1:7687 (neo4j:blood) ***\e[0m"\n\
    sleep 7; /opt/BloodHound-linux-x64/BloodHound --no-sandbox 2>/dev/null\n' > /opt/run.sh &&\
    chmod +x /opt/run.sh

# Clean up
RUN apt-get clean &&\
    apt-get clean autoclean &&\
    apt-get autoremove -y &&\
    rm -rf /tmp/* &&\
    rm -rf /var/lib/{apt,dpkg,cache,log}/


WORKDIR /data
CMD ["/opt/run.sh"]
