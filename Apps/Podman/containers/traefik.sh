#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/containers/traefik.sh | bash
#!/bin/bash

cd ~/containers
#Setup containers Drives
mkdir -p traefik
cd traefik
#Create container compose file
cat > compose.yaml < 'EOF'
"secrets:
  cf-token:
    file: ./cf-token
services:
  traefik:
    image: traefik:latest # or traefik:v3.3 to pin a version
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true # helps to increase security
    secrets:
      - cf-token # the secret at the top of this file
    env_file:
      - .env # store other secrets e.g., dashboard password
    networks:
      - proxy
    ports:
      - 80:80
      - 443:443
    # - 10000:10000 # optional
    # - 33073:33073 # optional
    environment:
      - TRAEFIK_DASHBOARD_CREDENTIALS=${TRAEFIK_DASHBOARD_CREDENTIALS}
      # - CF_API_EMAIL=your@email.com # Cloudflare email
      # - CF_DNS_API_TOKEN=YOUR-TOKEN # Cloudflare API Token
      - CF_DNS_API_TOKEN_FILE=/run/secrets/cf-token # see https://doc.traefik.io/traefik/https/acme/#providers
      # token file is the proper way to do it
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /run/user/1000/podman/podman.sock:/var/run/docker.sock:ro
      - /root/dockge/stacks/traefik/config/traefik.yaml:/traefik.yaml:ro
      - /root/dockge/stacks/traefik/config/acme.json:/acme.json
      - /root/dockge/stacks/traefik/config/config.yaml:/config.yaml:ro
      - /root/dockge/stacks/traefik/config/logs:/var/log/traefik
    labels:
      - traefik.enable=true
      - traefik.http.routers.traefik.entrypoints=http
      - traefik.http.routers.traefik.rule=Host(`traefik.${FQDN}`)
      - traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_DASHBOARD_CREDENTIALS}
      - traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto=https
      - traefik.http.routers.traefik.middlewares=traefik-https-redirect
      - traefik.http.routers.traefik-secure.entrypoints=https
      - traefik.http.routers.traefik-secure.rule=Host(`traefik.${FQDN}`)
      - traefik.http.routers.traefik-secure.middlewares=traefik-auth
      - traefik.http.routers.traefik-secure.tls=true
      - traefik.http.routers.traefik-secure.tls.certresolver=cloudflare
      - traefik.http.routers.traefik-secure.tls.domains[0].main=${FQDN}
      - traefik.http.routers.traefik-secure.tls.domains[0].sans=*.${FQDN}
      - traefik.http.routers.traefik-secure.service=api@internal
networks:
  proxy:
    #external: true # or uncomment this line to stop auto create the network
" EOF

#Create .env file
echo "TRAEFIK_DASHBOARD_CREDENTIALS= ### Run in terminal: echo $(htpasswd -nB the-new-username) | sed -e s/\\$/\\$\\$/g
FQDN=sample.com" > .env
#Create cf-tocken
echo "your-tocken-here" > cf-tocken
