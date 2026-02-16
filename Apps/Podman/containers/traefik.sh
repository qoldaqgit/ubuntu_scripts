#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/containers/traefik.sh | bash
#!/bin/bash

cd ~/containers
#Setup containers Drives
mkdir -p traefik traefik/config
cd traefik
#Create container compose file
cat > compose.yaml << 'EOF'
secrets:
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
EOF

#Create .env file
cat > .env << 'EOF'
TRAEFIK_DASHBOARD_CREDENTIALS= ### Run in terminal: echo $(htpasswd -nB the-new-username) | sed -e s/\\$/\\$\\$/g
FQDN=your.domain
EOF
#Create cf-tocken
echo "your-tocken-here" > cf-tocken

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
# Middleware for Adding BASIC Authentication to the sites
    test-auth:
      basicAuth:
        users:
          - "admin:$2y$05$miO/T3.mzggzXOtCRFkDuuAHEh2SyX0K7arEFuFa1ncRg6FpAH7Fq"

# Routes to external (not on same host) services
  routers:
    omada:
      entryPoints:
        - "https"
      rule: "Host(`omada.your.domain`)"
      middlewares:
        - https-redirectscheme
      tls: {}
      service: omada
    dockge:
      entryPoints:
        - "https"
      rule: "Host(`dockge.your.domain`)"
      middlewares:
        - https-redirectscheme
      tls: {}
      service: dockge

#Match Route with service
  services:
    omada:
      loadBalancer:
        servers:
          - url: "https://server-ip:8043"
        passHostHeader: true
    dockge:
      loadBalancer:
        servers:
          - url: "http://server-ip:5001"
        passHostHeader: true
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
