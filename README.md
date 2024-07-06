Name: k3s-workbench
Mode: Full Clone
Target Storage: tank
IP Config/IPv/4: 10.10.100.220/23
IP Config/Gateway: 10.10.100.1

apt install git
git clone https://github.com/ryanwclark1/homelab.git
export TERM=xterm-256color


|  Hostname   |          CPU           |          CPU           |  RAM  |         GPU         | Role  |  OS   | State |
| :---------: | :----------------------: | :--------------------: | :---: | :-------------------------: | :---: | :---: | :---: |
|   `judas`   |  [ROG-STRIX-B650E-WIFI]  |  [AMD Ryzen 9 7900X]   | 64GB  |   [AMD Radeon RX 7800 XT]   |   🖥️   |   ❄️   |   ✅   |
| `frametop`  | [Framework-13in-12thGen] |    [Intel i7-1260P]    | 64GB  |  [Intel Iris XE Graphics]   |   💻️   |   ❄️   |   ✅   |
| `steamdeck` |     [SteamDeck-OLED]     |      Zen 2 4c/8t       | 16GB  |        8 RDNA 2 CUs         |   🎮️   |   🐧   |   ✅   |
|    `vm1`    |          [QEMU]          |           -            |   -   |           [VirGL]           |   🐄   |   ❄️   |   ✅   |
|    `mv2`    |          [QEMU]          |           -            |   -   |           [VirGL]           |   🐄   |   ❄️   |   ✅   |
|   `nuc1`    |       [NUC6i7KYK]        | [Intel Core i7-6770HQ] | 64GB  | Intel Iris Pro Graphics 580 |   ☁️   |   ❄️   |   🚧   |
|   `nuc2`    |       [NUC5i7RYH]        | [Intel Core i7-5557U]  | 32GB  |  Intel Iris Graphics 6100   |   ☁️   |   ❄️   |   🧟   |


**Key**

- 🎭️ : Dual boot
- 🖥️ : Desktop
- 💻️ : Laptop
- 🎮️ : Games Machine
- 🐄 : Virtual Machine
- ☁️ : Server