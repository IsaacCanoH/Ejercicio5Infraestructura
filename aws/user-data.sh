#!/bin/bash
set -Eeuo pipefail

exec > >(tee -a /var/log/gestor-bootstrap.log) 2>&1

# Instalar Docker y Git.
dnf install -y docker git
command -v curl >/dev/null || dnf install -y curl-minimal

systemctl enable --now docker
usermod -aG docker ec2-user

# Habilitar la administracion mediante Systems Manager.
if ! rpm -q amazon-ssm-agent >/dev/null; then
  dnf install -y \
    https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
fi

systemctl enable --now amazon-ssm-agent

# Descargar y verificar Docker Compose.
compose_version="v5.6.0"
compose_asset="docker-compose-linux-x86_64"
compose_url="https://github.com/docker/compose/releases/download/${compose_version}"
compose_tmp=$(mktemp -d)

curl --fail --silent --show-error --location --retry 3 \
  "$compose_url/$compose_asset" -o "$compose_tmp/$compose_asset"

curl --fail --silent --show-error --location --retry 3 \
  "$compose_url/$compose_asset.sha256" -o "$compose_tmp/$compose_asset.sha256"

(cd "$compose_tmp" && sha256sum --check "$compose_asset.sha256")

install -d -m 0755 /usr/local/lib/docker/cli-plugins
install -m 0755 "$compose_tmp/$compose_asset" \
  /usr/local/lib/docker/cli-plugins/docker-compose

rm -f "$compose_tmp/$compose_asset" "$compose_tmp/$compose_asset.sha256"
rmdir "$compose_tmp"

# Preparar la carpeta del proyecto.
install -d -m 0750 -o ec2-user -g ec2-user /opt/gestor

# Agregar memoria de intercambio como apoyo.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 0600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  printf '/swapfile none swap sw 0 0\n' >> /etc/fstab
fi

docker --version
docker compose version
printf 'Preparacion del servidor terminada.\n'