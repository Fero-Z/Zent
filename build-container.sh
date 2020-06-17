sudo apt update

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common unzip npm nginx

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

apt-cache policy docker-ce

echo " ----- Install Docker ----- "

sudo apt install -y docker-ce 

echo " ----- Install Docker Compose ----- "

sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version


mkdir /datadrive/zent/lib/Zentd -p

docker-compose up -d

#sudo docker build --rm -f "Dockerfile" -t zent-cash:latest "."