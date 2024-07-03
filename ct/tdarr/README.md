# Tdarr LXC
![alt text](../../media/images/tdarr.png)

[Tdarr](https://tdarr.io) is a media transcoding application designed to automate the transcode and remux management of a media library. It uses conditional-based processing to determine the required encoding and remux operations for each file in the library. The software integrates with popular media management tools, such as Sonarr and Radarr, to ensure that newly added media files are automatically processed and optimized for the user's desired playback device. Tdarr provides a web-based interface for monitoring and managing the transcoding process, and also supports real-time logging and reporting. The software is designed to be flexible and configurable, with a wide range of encoding and remux options available to users. Tdarr is an ideal solution for media enthusiasts who want to optimize their library for seamless playback on a variety of devices, while also streamlining the management and maintenance of their media library.

To create a new Proxmox VE Tdarr LXC, run the command below in the Proxmox VE Shell.

```console
bash -c "$(wget -qLO - https://github.com/ryanwclark1/homelab/raw/main/ct/tdarr.sh)"
```

Default Settings: 2GB RAM - 4GB Storage - 2vCPU

**Tdarr Interface: IP:8265**