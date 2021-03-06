# DESCRIPTION:    Slic3r Prusa3D edition in a Docker container
# AUTHOR:         davidk
# COMMENTS:       This Dockerfile wraps Prusa3D's fork of Slic3r into a Docker
#                 container with settings for the Prusa i3 MK2.
#
#                 Tested on Fedora 25.
#                 Derived from Jess Frazelle's Atom Dockerfile
#                 https://raw.githubusercontent.com/jessfraz/dockerfiles/master/atom/Dockerfile
#
# USAGE:
#
#         # Build image
#         docker build -t slic3r .
#
#         # Run it!
#         docker run -v /tmp/.X11-unix:/tmp/.X11-unix -v $PWD:/Slic3r/3d:z -v slic3rSettings:/home/slic3r -e DISPLAY=$DISPLAY --rm keyglitch/docker-slic3r-prusa3d
#
#         # If this fails, it might either be SELinux or
#         # just needing to allow access to your local X session
#         xhost local:root
#
# VOLUME MANAGEMENT:
#
#         # Remove and wipe settings
#         docker volume rm slic3rSettings
#
#         # Information about where stuff is
#         docker volume inspect slic3rSettings

FROM debian:stretch

RUN apt-get update && apt-get install -y \
  freeglut3 \
  libgtk2.0-dev \
  libwxgtk3.0-dev \
  libwx-perl \
  libxmu-dev \
  libgl1-mesa-glx \
  libgl1-mesa-dri \
  xdg-utils \
  --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove -y \
  && apt-get autoclean

RUN groupadd slic3r \
  && useradd -g slic3r --create-home --home-dir /home/slic3r slic3r \
  && mkdir -p /Slic3r \
  && chown slic3r:slic3r /Slic3r

WORKDIR /Slic3r
ADD getLatestSlic3rRelease.sh /Slic3r
RUN chmod +x /Slic3r/getLatestSlic3rRelease.sh

RUN apt-get update && apt-get install -y \
  jq \
  curl \
  ca-certificates \
  unzip \
  bzip2 \
  --no-install-recommends \
  && latestSlic3r=$(/Slic3r/getLatestSlic3rRelease.sh url) \
  && slic3rReleaseName=$(/Slic3r/getLatestSlic3rRelease.sh name) \
  && curl -sSL ${latestSlic3r} > ${slic3rReleaseName} \
  && rm -f /Slic3r/releaseInfo.json \
  && curl -sSL https://github.com/prusa3d/Slic3r-settings/archive/master.zip > /Slic3r/slic3r-settings.zip \
  && mkdir -p /Slic3r/slic3r-dist \
  && tar -xjf ${slic3rReleaseName} -C /Slic3r/slic3r-dist --strip-components 1 \
  && unzip -q slic3r-settings.zip \
  && mkdir -p /home/slic3r/.Slic3r/ \
  && cp -a /Slic3r/Slic3r-settings-master/Slic3r\ settings\ MK2/* /home/slic3r/.Slic3r/ \
  && rm -f /Slic3r/${slic3rReleaseName} \
  && rm -f /Slic3r/slic3r-settings.zip \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get purge -y --auto-remove jq curl ca-certificates unzip bzip2 \
  && apt-get autoclean \
  && chown -R slic3r:slic3r /Slic3r /home/slic3r

USER slic3r

# Settings storage
RUN mkdir -p /home/slic3r/.local/share/

VOLUME /home/slic3r/

ENTRYPOINT [ "/Slic3r/slic3r-dist/slic3r", "--gui" ]
