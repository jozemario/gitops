#!/bin/bash

apt update
sudo apt install net-tools
apt install libhtml-parser-perl
curl -o webmin-setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repos.sh
sh webmin-setup-repos.sh
apt-get install webmin --install-recommends
apt install docker.io
apt-get install dnsutils

# node setup
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san 201.205.178.45" sh -s - --docker
cat /etc/rancher/k3s/k3s.yaml 



docker pull docker.io/rancher/klipper-helm:v0.9.3-build20241008
docker pull docker.io/rancher/klipper-lb:v0.4.9
docker pull docker.io/rancher/local-path-provisioner:v0.0.30
docker pull docker.io/rancher/mirrored-coredns-coredns:1.12.0
docker pull docker.io/rancher/mirrored-library-busybox:1.36.1
docker pull docker.io/rancher/mirrored-library-traefik:2.11.10
docker pull docker.io/rancher/mirrored-metrics-server:v0.7.2
docker pull docker.io/rancher/mirrored-pause:3.6


docker tag docker.io/rancher/mirrored-pause:3.6 docker.mghcloud.com:5000/rancher/mirrored-pause:3.6
docker tag docker.io/rancher/klipper-helm:v0.9.3-build20241008 docker.mghcloud.com:5000/rancher/klipper-helm:v0.9.3-build20241008
docker tag docker.io/rancher/klipper-lb:v0.4.9 docker.mghcloud.com:5000/rancher/klipper-lb:v0.4.9
docker tag docker.io/rancher/local-path-provisioner:v0.0.30 docker.mghcloud.com:5000/rancher/local-path-provisioner:v0.0.30
docker tag docker.io/rancher/mirrored-coredns-coredns:1.12.0 docker.mghcloud.com:5000/rancher/mirrored-coredns-coredns:1.12.0
docker tag docker.io/rancher/mirrored-library-busybox:1.36.1 docker.mghcloud.com:5000/rancher/mirrored-library-busybox:1.36.1
docker tag docker.io/rancher/mirrored-library-traefik:2.11.10 docker.mghcloud.com:5000/rancher/mirrored-library-traefik:2.11.10
docker tag docker.io/rancher/mirrored-metrics-server:v0.7.2 docker.mghcloud.com:5000/rancher/mirrored-metrics-server:v0.7.2


docker push docker.mghcloud.com:5000/rancher/mirrored-pause:3.6
docker push docker.mghcloud.com:5000/rancher/klipper-helm:v0.9.3-build20241008
docker push docker.mghcloud.com:5000/rancher/klipper-lb:v0.4.9
docker push docker.mghcloud.com:5000/rancher/local-path-provisioner:v0.0.30
docker push docker.mghcloud.com:5000/rancher/mirrored-coredns-coredns:1.12.0
docker push docker.mghcloud.com:5000/rancher/mirrored-library-busybox:1.36.1
docker push docker.mghcloud.com:5000/rancher/mirrored-library-traefik:2.11.10
docker push docker.mghcloud.com:5000/rancher/mirrored-metrics-server:v0.7.2


Use local DNS parameter
On each node, you could say that you want to use the host's resolv parameters. If k3s is managed as systemd service (which is probably the case), you could
 just edit /etc/systemd/system/k3s.service.env to add you system's resolv.conf

K3S_RESOLV_CONF=/etc/resolv.conf
and then restart the service

sudo systemctl status k3s
plus: the easiest solution, easily scriptable
cons: you'll need to do it on each of your nodes (from what I understand). Different resolv.conf on different systems involves that the very same deployment might not act the same way depending on the nodes used by kube