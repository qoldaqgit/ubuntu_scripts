mkdir smb
cd smb/
mkdir data

# --name [Container name on Host]
# -v [Host location]:[Container Location]
# -s “[public name];[file path];[Yes/No browsable];[Yes/No readonly];[Yes/No guest];[authorized user]”
version: "3"
services:
    samba:
        restart: unless-stopped
        container_name: NAS
        deploy:
            resources:
                limits:
                    memory: 4096m
        ports:
            - 139:139
            - 445:445
        volumes:
            - ./data:/multimedia
        image: dperson/samba
        command: -u "user;1234" -s "multimedia;/multimedia;yes;no;no;user"
