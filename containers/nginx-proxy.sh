mkdir nginx
cd nginx/
mkdir data letsencrypt

#Create docker compose file
echo "version: '3.8'
services:
  app:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt" >| 'docker-compose.yml'

#run docker
sudo docker-compose up -d

echo "
#Login
admin@example.com
Password: changeme
"
