#!/command/with-contenv sh

apk update
apk add --no-cache \
  onevpl-libs \
  onevpl-dev \
  onevpl \
  svt-av1 \
  svt-av1-dev \
  libva-utils \
  intel-media-sdk \
  intel-media-sdk-dev \
  intel-media-driver \
  intel-media-driver-dev \
  intel-gmmlib \
  libva-intel-driver \

  # libva libdav1d
