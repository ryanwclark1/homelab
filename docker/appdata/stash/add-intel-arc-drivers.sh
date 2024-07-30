#!/command/with-contenv sh

apk update
apk add --no-cache \
  onevpl \
  onevpl-libs \
  onevpl-dev \
  onevpl-doc \
  svt-av1 \
  svt-av1-dev \
  libva \
  libva-dev \
  libva-utils \
  libva-glx \
  libva-glx-dev \
  intel-media-sdk \
  intel-media-sdk-dev \
  intel-media-driver \
  intel-media-driver-dev \
  intel-gmmlib \
  libva-intel-driver
apk add onevpl-intel-gpu onevpl-intel-gpu-dev  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing
  #  libdav1d
