#!/usr/bin/env bash

# 更新系统和安装基础软件
apt update -y
apt install sudo -y
apt install wget -y
apt install curl -y

# 配置SSH密钥
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMRrupHDuIUnaHDpQ9GeaQN62yIh1Br+F295ADb5kZ/b Generated By Termius" > ~/.ssh/authorized_keys

# 配置SSH服务
ssh_config="/etc/ssh/sshd_config"
new_port=51888

# 定义SSH配置
declare -A conf
conf=(
    ["PubkeyAuthentication"]="PubkeyAuthentication yes"
    ["AuthorizedKeysFile"]="AuthorizedKeysFile .ssh/authorized_keys"
    ["Port"]="Port ${new_port}"
    ["PermitRootLogin"]="PermitRootLogin yes"
    ["PasswordAuthentication"]="PasswordAuthentication no"
    ["ClientAliveInterval"]="ClientAliveInterval 60"
    ["ClientAliveCountMax"]="ClientAliveCountMax 30"
    ["RSAAuthentication"]="RSAAuthentication yes"
)

# 应用SSH配置
for key in ${!conf[@]}; do
    value=${conf[$key]}
    # 使用grep -w精确匹配key值，如果存在则整行替换，不存在则添加
    if grep -qw $key $ssh_config ; then
        sed -i "/$key/c$value" $ssh_config
    else
        echo $value >> $ssh_config
    fi
done

# 重启SSH服务
systemctl restart sshd

# 配置防火墙
apt install ufw -y
ufw default allow outgoing 
ufw default deny incoming
ufw allow 51888

# 设置虚拟内存
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab 

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# 挂探针
mkdir -p /root/cgent
docker run -d -v=/root/cgent/:/root/ \
    --name=cgent --restart=always --net=host --cap-add=NET_RAW \
    -e SECRET=8vb0R7wuNjrXdxZgkrNQAgsRhfyhtesF -e SERVER=nezha.buzhi.de:443 -e TLS=true \
    ghcr.io/yosebyte/cgent
