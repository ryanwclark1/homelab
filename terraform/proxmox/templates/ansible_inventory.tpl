[masters]
%{ for name, node in master_nodes ~}
${name} ansible_host=${split("/", node.ip_address)[0]} ansible_user=${split("@", node.ssh_host)[0]}
%{ endfor ~}

[workers]
%{ for name, node in worker_nodes ~}
${name} ansible_host=${split("/", node.ip_address)[0]} ansible_user=${split("@", node.ssh_host)[0]}
%{ endfor ~}

[storage]
%{ for name, node in storage_nodes ~}
${name} ansible_host=${split("/", node.ip_address)[0]} ansible_user=${split("@", node.ssh_host)[0]}
%{ endfor ~}

[k3s_cluster:children]
masters
workers
storage

[k3s_cluster:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
