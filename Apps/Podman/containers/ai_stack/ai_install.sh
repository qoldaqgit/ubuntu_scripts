# curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/containers/ai_stack/ai_install.sh | bash
#!/bin/bash

cd /app/stacks
#Setup containers Drives
mkdir -p ai_stack ai_stack/config
cd ai_stack

cat > init-db.sql << 'EOF'
CREATE DATABASE litellm;
CREATE DATABASE n8n;
EOF

#Create container compose file
cat > compose.yaml << 'EOF'
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    environment:
      - TUNNEL_TOKEN=${CF_DNS_TUNNEL_TOKEN}
    restart: unless-stopped
    command: tunnel --no-autoupdate run
    networks:
      - intra_net
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    env_file:
      - .env
    ports:
      - 80:80
      - 443:443
    environment:
      - TRAEFIK_DASHBOARD_CREDENTIALS=${TRAEFIK_DASHBOARD_CREDENTIALS}
      - CF_API_EMAIL=${CF_API_EMAIL}# Cloudflare email
      - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /run/user/1000/podman/podman.sock:/var/run/docker.sock:ro
      - ./config/traefik.yaml:/traefik.yaml:ro
      - ./config/acme.json:/acme.json
      - ./config/config.yaml:/config.yaml:ro
      - ./config/logs:/var/log/traefik
    labels:
      - traefik.enable=true
      - traefik.http.routers.${TRAEFIK_SUBDOMAIN}.entrypoints=http
      - traefik.http.routers.${TRAEFIK_SUBDOMAIN}.rule=Host(`${TRAEFIK_SUBDOMAIN}.${FQDN}`)
      - traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_DASHBOARD_CREDENTIALS}
      - traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto=https
      - traefik.http.routers.traefik.middlewares=traefik-https-redirect
      - traefik.http.routers.traefik-secure.entrypoints=https
      - traefik.http.routers.traefik-secure.rule=Host(`${TRAEFIK_SUBDOMAIN}.${FQDN}`)
      - traefik.http.routers.traefik-secure.middlewares=traefik-auth
      - traefik.http.routers.traefik-secure.tls=true
      - traefik.http.routers.traefik-secure.tls.certresolver=cloudflare
      - traefik.http.routers.traefik-secure.tls.domains[0].main=${FQDN}
      - traefik.http.routers.traefik-secure.tls.domains[0].sans=*.${FQDN}
      - traefik.http.routers.traefik-secure.service=api@internal
    networks:
      - intra_net
  open-webui:
    volumes:
      - ./open-webui:/app/backend/data
    container_name: open-webui
    restart: always
    image: ghcr.io/open-webui/open-webui:main
    #image: localhost/open-webui-mssql
    labels:
      - traefik.enable=true
      - traefik.http.routers.${OPENWEBUI_SUBDOMAIN}.entrypoints=https
      - traefik.http.routers.${OPENWEBUI_SUBDOMAIN}.rule=Host(`${OPENWEBUI_SUBDOMAIN}.${FQDN}`)
      - traefik.http.routers.${OPENWEBUI_SUBDOMAIN}.tls=true
      - traefik.http.services.${OPENWEBUI_SUBDOMAIN}.loadbalancer.server.port=8080
    networks:
      - intra_net
  db:
    image: postgres:16
    container_name: postgres
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: default_db
    volumes:
      - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
      - ./postgres_data1:/var/lib/postgresql/data
   # ports:
   #   - ${POSTGRESDB_PORT}:5432
    healthcheck:
      test:
        - CMD-SHELL
        - pg_isready -d default_db -U ${POSTGRES_USER}
      interval: 1s
      timeout: 5s
      retries: 10
    networks:
      - intra_net
  litellm:
    build:
      context: .
      args:
        target: runtime
    image: docker.litellm.ai/berriai/litellm:main-stable
    container_name: litellm
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRESDB_HOST}:${POSTGRESDB_PORT}/${LITELLM_DATABASE}
      STORE_MODEL_IN_DB: "True" # allows adding models to proxy via UI
    env_file:
      - .env # Load local .env file
    labels:
      - traefik.enable=true
      - traefik.http.routers.${LITELLM_SUBDOMAIN}.entrypoints=https
      - traefik.http.routers.${LITELLM_SUBDOMAIN}.rule=Host(`${LITELLM_SUBDOMAIN}.${FQDN}`)
      - traefik.http.routers.${LITELLM_SUBDOMAIN}.tls=true
      - traefik.http.services.${LITELLM_SUBDOMAIN}.loadbalancer.server.port=4000
    depends_on:
      - ${POSTGRESDB_HOST} # Indicates that this service depends on the 'db' service, ensuring 'db' starts first
    healthcheck:
      # Defines the health check configuration for the container
      test:
        - CMD-SHELL
        - python3 -c "import urllib.request;
          urllib.request.urlopen('http://localhost:4000/health/liveliness')" # Command to execute for health check
      interval: 30s # Perform health check every 30 seconds
      timeout: 10s # Health check command times out after 10 seconds
      retries: 3 # Retry up to 3 times if health check fails
      start_period: 40s # Wait 40 seconds after container start before beginning health checks
    networks:
      - intra_net
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    environment:
      - N8N_HOST=${N8N_HOST:-0.0.0.0} # Bind to all interfaces (adjust if behind proxy)
      - N8N_PORT=${N8N_PORT:-5678}
      - N8N_PROTOCOL=${N8N_PROTOCOL:-http} # Use https if behind SSL terminator (e.g., Nginx, Traefik)
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=${POSTGRESDB_HOST:-db} # External PostgreSQL host (e.g., db.example.com)
      - DB_POSTGRESDB_PORT=${POSTGRESDB_PORT:-5432}
      - DB_POSTGRESDB_DATABASE=${N8N_DATABASE:-n8n}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true # Optional: enable basic auth for n8n UI
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY} # CRITICAL: set a strong random key for data encryption
      - WEBHOOK_URL=${N8N_WEBHOOK_URL:-http://localhost:5678} # Adjust if behind proxy/domain
      - GENERIC_TIMEZONE=${SYSTEM_TIMEZONE}
      - TZ=${SYSTEM_TIMEZONE}
    volumes:
      - n8n_data:/home/node/.n8n
      - ./local-files:/files
      #- ./n8n_data:/home/node/.n8n # Persist n8n config, workflows, credentials (optional but recommended)
    labels:
      - traefik.enable=true
      - traefik.http.routers.${N8N_SUBDOMAIN}.entrypoints=https
      - traefik.http.routers.${N8N_SUBDOMAIN}.rule=Host(`${N8N_SUBDOMAIN}.${FQDN}`)
      - traefik.http.routers.${N8N_SUBDOMAIN}.tls=true
      - traefik.http.services.${N8N_SUBDOMAIN}.loadbalancer.server.port=5678
    depends_on:
      - ${POSTGRESDB_HOST}
    networks:
      - intra_net
volumes:
  n8n_data: null
networks:
  intra_net:
    external: true
EOF

#Create .env file
cat > .env << 'EOF'
TRAEFIK_DASHBOARD_CREDENTIALS= ### Run in terminal: echo $(htpasswd -nB the-new-username) | sed -e s/\\$/\\$\\$/g
FQDN=your.domain

#System
SYSTEM_TIMEZONE=America/New_York
#Domain
FQDN=your.domain
#Cloudflared
CF_API_EMAIL=admin@${FQDN}
CF_DNS_API_TOKEN=your_token
CF_DNS_TUNNEL_TOKEN=your_tunnel
#Traefik
TRAEFIK_DASHBOARD_CREDENTIALS= ### Run in terminal: echo $(htpasswd -nB the-new-username) | sed -e s/\\$/\\$\\$/g
TRAEFIK_SUBDOMAIN=traefik
#Open WebUI
OPENWEBUI_SUBDOMAIN=ai
#Postgres DB
POSTGRES_USER=dbuser
POSTGRES_PASSWORD=dbpassword
POSTGRESDB_PORT=5432
POSTGRESDB_HOST=db
#LiteLLM
LITELLM_MASTER_KEY=litellmpassword
LITELLM_SALT_KEY=litellmsalt
LITELLM_SUBDOMAIN=litellm
LITELLM_DATABASE=litellm
#N8N
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https  # Change to https if you terminate SSL externally (e.g., Nginx, Traefik, 
N8N_SUBDOMAIN=n8n
N8N_DATABASE=n8n
N8N_WEBHOOK_URL=https://${N8N_SUBDOMAIN}.${FQDN}
#N8N Security - Generate these!
N8N_ENCRYPTION_KEY=n8nkey
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=password
EOF

cd config
cat > config.yaml << 'EOF'
http:
  middlewares:    
    default-security-headers:
      headers:
        customBrowserXSSValue: 0                            # X-XSS-Protection=1; mode=block
        contentTypeNosniff: true                          # X-Content-Type-Options=nosniff
        forceSTSHeader: true                              # Add the Strict-Transport-Security header even when the connection is HTTP
        frameDeny: false                                   # X-Frame-Options=deny
        referrerPolicy: "strict-origin-when-cross-origin"
        stsIncludeSubdomains: true                        # Add includeSubdomains to the Strict-Transport-Security header
        stsPreload: true                                  # Add preload flag appended to the Strict-Transport-Security header
        stsSeconds: 3153600                              # Set the max-age of the Strict-Transport-Security header (63072000 = 2 years)
        contentSecurityPolicy: "default-src 'self'"     
        customRequestHeaders:
          X-Forwarded-Proto: https
    https-redirectscheme:
      redirectScheme:
        scheme: https
        permanent: true

EOF
cat > traefik.yaml << 'EOF'
api:
  dashboard: true
  debug: true
entryPoints:
  http:
    address: ":80"
    http:
    #  middlewares: # uncomment if using CrowdSec - see my video
    #    - crowdsec-bouncer@file
      redirections:
        entrypoint:
          to: https
          scheme: https
  https:
    address: ":443"
    # http:
    #  middlewares: # uncomment if using CrowdSec - see my video
    #    - crowdsec-bouncer@file
  # tcp:
   # address: ":10000"
  # apis:
   # address: ":33073"
serversTransport:
  insecureSkipVerify: true
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    filename: /config.yaml # example provided gives A+ rating https://www.ssllabs.com/ssltest/
certificatesResolvers:
  cloudflare:
    acme:
      # caServer: https://acme-v02.api.letsencrypt.org/directory # production (default)
      # caServer: https://acme-staging-v02.api.letsencrypt.org/directory # staging (testing)
      email: admin@your.domain # Cloudflare email (or other provider)
      storage: acme.json
      dnsChallenge:
        provider: cloudflare # change as required
        # disablePropagationCheck: true # Some people using Cloudflare note this can solve DNS propagation issues.
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"

log:
  level: "INFO"
  filePath: "/var/log/traefik/traefik.log"
accessLog:
  filePath: "/var/log/traefik/access.log"
EOF
touch acme.json
chmod 600 acme.json
sudo apt install apache2-utils
