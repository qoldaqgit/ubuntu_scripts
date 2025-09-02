mkdir uptime-kuma && cd uptime-kuma
mkdir data 
echo 'services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    volumes:
      - ./data:/app/data
    ports:
      # <Host Port>:<Container Port>
      - 3001:3001
    restart: unless-stopped' > docker-compose.yml


sudo docker-compose up -d
