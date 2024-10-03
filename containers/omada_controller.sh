#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/containers/omada_controller.sh | bash
mkdir omada
cd omada/
mkdir data logs

#Create docker compose file
echo "version: '3'
services:
    omada-controller:
        container_name: omada-controller
        stop_grace_period: \"60\"
        restart: unless-stopped
        ulimits:
            nofile:
                soft: 4096
                hard: 8192
        ports:
            - 8088:8088
            - 8043:8043
            - 8843:8843
            - 27001:27001/udp
            - 29810:29810/udp
            - 29811-29816:29811-29816
        environment:
            - MANAGE_HTTP_PORT=8088
            - MANAGE_HTTPS_PORT=8043
            - PGID=508
            - PORTAL_HTTP_PORT=8088
            - PORTAL_HTTPS_PORT=8843
            - PORT_ADOPT_V1=29812
            - PORT_APP_DISCOVERY=27001
            - PORT_DISCOVERY=29810
            - PORT_MANAGER_V1=29811
            - PORT_MANAGER_V2=29814
            - PORT_TRANSFER_V2=29815
            - PORT_RTTY=29816
            - PORT_UPGRADE_V1=29813
            - PUID=508
            - SHOW_SERVER_LOGS=true
            - SHOW_MONGODB_LOGS=false
            - SSL_CERT_NAME=tls.crt
            - SSL_KEY_NAME=tls.key
            - TZ=Etc/UTC
        volumes:
            - ./data:/opt/tplink/EAPController/data
            - ./logs:/opt/tplink/EAPController/logs
        image: mbentley/omada-controller:5.14
" >| 'docker-compose.yml'

#run docker
sudo docker-compose up -d
