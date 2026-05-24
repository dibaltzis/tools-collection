version: 2

ethernets:
  ens3:
    dhcp4: false

    addresses:
      - ${ip}/${cidr}

    routes:
      - to: default
        via: ${gateway}

    nameservers:
      addresses:
%{ for dns_server in dns ~}
        - ${dns_server}
%{ endfor ~}