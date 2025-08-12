mkdir -p openproject/{data,assets}
cd openproject
touch docker-compose.yml

echo "version: '3.8'
services:
  openproject:
    image: openproject/openproject:16
    container_name: openproject
    ports:
      - '8180:80'
    environment:
      OPENPROJECT_HOST__NAME: 10.10.10.30:8180
      OPENPROJECT_SECRET_KEY_BASE: mrMI3p1BCMkHNSsxdy1alWH4E94tC7qY
    volumes:
      - ~/openproject/data:/var/openproject/pgdata
      - ~/openproject/assets:/var/openproject/assets
    restart: unless-stopped
" > ~/openproject/docker-compose.yml
