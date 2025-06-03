#!/usr/bin/env bash

set -euo pipefail

cp ./restart-docker-downloads.sh /usr/local/bin/restart-docker-downloads.sh
chmod +x /usr/local/bin/restart-docker-downloads.sh

cp ./update-docker-downloads.sh /usr/local/bin/update-docker-downloads.sh
chmod +x /usr/local/bin/update-docker-downloads.sh

cp ./restart-docker-downloads.service /etc/systemd/system/restart-docker-downloads.service
cp ./restart-docker-downloads.timer /etc/systemd/system/restart-docker-downloads.timer
cp ./update-docker-downloads.service /etc/systemd/system/update-docker-downloads.service
cp ./update-docker-downloads.timer /etc/systemd/system/update-docker-downloads.timer

systemctl enable restart-docker-downloads.timer
systemctl enable update-docker-downloads.timer

systemctl start restart-docker-downloads.timer
systemctl start update-docker-downloads.timer

systemctl daemon-reexec
systemctl daemon-reload
systemctl start update-docker-downloads.service
