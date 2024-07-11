# Jellyfin Media Server LXC
## With Privileged/Unprivileged Hardware Acceleration Support
![alt text](../../media/images/jellyfin.png)

To create a new Proxmox VE Jellyfin Media Server LXC, run the command below in the Proxmox VE Shell.

```console
bash -c "$(wget -qLO - https://github.com/ryanwclark1/homelab/raw/main/ct/jellyfin.sh)"
```

Default Settings: 2GB RAM - 8GB Storage - 2vCPU

**Jellyfin Media Server Interface: IP:8096**

FFmpeg path: /usr/lib/jellyfin-ffmpeg/ffmpeg


Intel GPU
Resizable-BAR is not mandatory for hardware acceleration, but it can affect the graphics performance. It's recommended to enable the Resizable-BAR if the processor, motherboard and BIOS support it.

ASPM should be enabled in the BIOS if supported. This greatly reduces the idle power consumption of the ARC GPU.

Low-Power encoding is used by default on ARC GPUs. GuC & HuC firmware can be missing on older distros, you might need to manually download it from the Kernel firmware git.

Old kernel build configs may not have the MEI modules enabled, which are necessary for using ARC GPU on Linux.

$ sudo /usr/lib/jellyfin-ffmpeg/vainfo --all
Trying display: drm
libva info: VA-API version 1.21.0
libva info: Trying to open /usr/lib/jellyfin-ffmpeg/lib/dri/ast_drv_video.so
libva info: Trying to open /usr/lib/x86_64-linux-gnu/dri/ast_drv_video.so
libva info: Trying to open /usr/lib/dri/ast_drv_video.so
libva info: Trying to open /usr/local/lib/dri/ast_drv_video.so
libva info: va_openDriver() returns -1
vaInitialize failed with error code -1 (unknown libva error),exit