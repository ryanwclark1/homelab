qm clone 5001 221 \
  --name k3s-node01 \
  --full true \
  --target james \
  --storage init

qm set 221 --ipconfig0 ip=10.10.101.221/23,gw=10.10.100.1; \
qm move-disk 222 scsi0 tank; \
qm disk resize 221 scsi0 10G


qm clone 5001 222 \
  --name k3s-node02 \
  --full true \
  --target andrew \
  --storage init

ssh root@andrew.techcasa.io "qm set 222 --ipconfig0 ip=10.10.101.222/23,gw=10.10.100.1; \
qm move-disk 222 scsi0 tank; \
qm disk resize 222 scsi0 10G; \
exit"

qm clone 5001 223 \
  --name k3s-node03 \
  --full true \
  --target john \
  --storage init

ssh root@john.techcasa.io "qm set 223 --ipconfig0 ip=10.10.101.223/23,gw=10.10.100.1; \
qm move-disk 223 scsi0 tank; \
qm disk resize 223 scsi0 10G; \
exit"

qm clone 5001 224 \
  --name k3s-node04 \
  --full true \
  --target peter \
  --storage init

ssh root@peter.techcasa.io "qm set 224 --ipconfig0 ip=10.10.101.224/23,gw=10.10.100.1; \
qm move-disk 224 scsi0 tank; \
qm disk resize 224 scsi0 10G; \
exit"

qm clone 5001 225 \
  --name k3s-node05 \
  --full true \
  --target andrew \
  --storage init

ssh root@andrew.techcasa.io "qm set 225 --ipconfig0 ip=10.10.101.225/23,gw=10.10.100.1; \
qm move-disk 225 scsi0 tank; \
qm disk resize 225 scsi0 10G; \
exit"

qm clone 5001 226 \
  --name k3s-node06 \
  --full true \
  --target john \
  --storage init

ssh root@john.techcasa.io "qm set 226 --ipconfig0 ip=10.10.101.226/23,gw=10.10.100.1; \
qm move-disk 226 scsi0 tank; \
qm disk resize 226 scsi0 10G; \
exit"

qm clone 5001 227 \
  --name k3s-node07 \
  --full true \
  --target peter \
  --storage init

ssh root@peter.techcasa.io "qm set 227 --ipconfig0 ip=10.10.101.227/23,gw=10.10.100.1; \
qm move-disk 227 scsi0 tank; \
qm disk resize 227 scsi0 10G; \
exit"

qm clone 5001 228 \
  --name k3s-node08 \
  --full true \
  --target andrew \
  --storage init

ssh root@andrew.techcasa.io "qm set 228 --ipconfig0 ip=10.10.101.228/23,gw=10.10.100.1; \
qm move-disk 228 scsi0 tank; \
qm disk resize 228 scsi0 10G; \
exit"

qm clone 5001 229 \
  --name k3s-node09 \
  --full true \
  --target john \
  --storage init

ssh root@john.techcasa.io "qm set 229 --ipconfig0 ip=10.10.101.221/23,gw=10.10.100.1; \
qm move-disk 229 scsi0 tank; \
qm disk resize 221 scsi0 10G; \
exit"


qm clone 5001 230 \
  --name k3s-node10 \
  --full true \
  --target peter \
  --storage init

ssh root@peter.techcasa.io "qm set 221 --ipconfig0 ip=10.10.101.221/23,gw=10.10.100.1; \
qm move-disk 221 scsi0 tank; \
qm disk resize 221 scsi0 10G; \
exit"
