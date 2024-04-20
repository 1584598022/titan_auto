#!/bin/bash

# 切换到 /home 目录
cd /home || exit

# 创建四个文件夹
mkdir titan1 titan2 titan3 titan4

# 更新apt并安装必要的软件包
apt-get update
apt install -y build-essential golang docker*

# 下载并解压 Titan 节点软件
wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.16/titan_v0.1.16_linux_amd64.tar.gz
tar -xvf titan_v0.1.16_linux_amd64.tar.gz
mv titan_v0.1.16_linux_amd64 titan
echo 'export PATH="/home/titan:$PATH"' | sudo tee -a /etc/profile
source /etc/profile
sleep 1
#设置节点占用硬盘大小
titan-edge config set --storage-size 50GB

#启动节点
screen -d -m -S titan_node titan-edge daemon start --init --url https://hk-locator.titannet.io:5000/rpc/v0
sleep 10

#绑定
titan-edge bind --hash=FBB5393F-2461-44F2-8063-1CCD07919BA4 https://api-test1.container1.titannet.io/api/v2/device/binding

# 拉取 Docker 镜像
docker pull nezha123/titan-edge

# 创建 Dockerfile
cat <<EOF > Dockerfile
FROM nezha123/titan-edge
WORKDIR /root
ENTRYPOINT ["titan-edge", "daemon", "start", "--init", "--url", "https://hk-locator.titannet.io:5000/rpc/v0"]
EOF

# 构建 Docker 镜像
docker build -t my-titan-edge .

# 启动四个 Docker 容器
for i in {1..4}; do
    docker run -d --name titan$i --restart always -v /home/titan$i:/root/.titanedge/storage my-titan-edge
done
sleep 2

# 进入每个 Docker 并执行绑定命令
for i in {1..4}; do
    docker exec -it titan$i /bin/bash -c "titan-edge bind --hash=FBB5393F-2461-44F2-8063-1CCD07919BA4 https://api-test1.container1.titannet.io/api/v2/device/binding"
done
