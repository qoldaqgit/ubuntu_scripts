sudo apt update
#install Docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo apt update && sudo apt upgrade -y

#install Docker compose
sudo apt install docker-compose -y
