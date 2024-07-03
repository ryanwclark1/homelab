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