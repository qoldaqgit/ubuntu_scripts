#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Omada%20Controller/latest.sh | bash
#!/bin/bash

clear
echo '#######################################################'
echo '##                                                   ##'
echo '##     Installing of TP-Link Omada Controller        ##'
echo '##                                                   ##'
echo '#######################################################'

echo "[+] Verifying running as root"
if [ `id -u` -ne 0 ]; then
  echo -e "\e[1;31m[!] Script requires to be ran as root. Please rerun using sudo. \e[0m"
  exit
fi

echo "[+] Verifying supported OS"
OS=$(hostnamectl status | grep "Operating System" | sed 's/^[ \t]*//')
echo "[~] $OS"

if [[ $OS = *"Ubuntu 20.04"* ]]; then
    OsVer=focal
elif [[ $OS = *"Ubuntu 22.04"* ]]; then
    OsVer=jammy
elif [[ $OS = *"Ubuntu 24.04"* ]]; then
    OsVer=noble
else
    echo -e "\e[1;31m[!] Script currently only supports Ubuntu 20.04, 22.04 or 24.04! \e[0m"
    exit
fi

echo "[+] Installing script prerequisites"
apt-get -qq update
apt-get -qq install gnupg curl &> /dev/null

echo "[+] Verifying supported CPU"
if ! lscpu | grep -iq avx; then
    echo "		[+] Importing the MongoDB 4.4 PGP key and creating the APT repository"
    curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc |  gpg -o /usr/share/keyrings/mongodb-server-4.4.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] https://repo.mongodb.org/apt/ubuntu $OsVer/mongodb-org/4.4 multiverse" > /etc/apt/sources.list.d/mongodb-org-4.4.list

else
    echo "	[+] Importing the MongoDB 8.0 PGP key and creating the APT repository"
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $OsVer/mongodb-org/8.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-8.0.list
    apt-get -qq update
fi

echo "[+] Downloading the latest Omada Software Controller package"
OmadaPackageUrl=$(curl -fsSL https://support.omadanetworks.com/us/product/omada-software-controller/?resourceType=download | grep -oPi '<a[^>]*href="\K[^"]*linux_x64_[0-9]*\.deb[^"]*' | head -n 1)
OmadaPackageBasename=$(basename $OmadaPackageUrl)
curl -sLo /tmp/$OmadaPackageBasename $OmadaPackageUrl

# Package dependencies
echo "[+] Installing MongoDB 8.0"
apt-get -qq install mongodb-org &> /dev/null
echo "[+] Installing OpenJDK 21 JRE (headless)"
apt-get -qq install openjdk-21-jre-headless &> /dev/null
echo "[+] Installing JSVC"
apt-get -qq install jsvc &> /dev/null

echo "[+] Installing Omada Software Controller $(echo $OmadaPackageBasename | tr "_" "\n" | sed -n '4p')"
dpkg -i /tmp/$OmadaPackageBasename &> /dev/null

hostIP=$(hostname -I | cut -f1 -d' ')
echo -e "\e[0;32m[~] Omada Software Controller has been successfully installed! :)\e[0m"
echo -e "\e[0;32m[~] Please visit https://${hostIP}:8043 to complete the inital setup wizard.\e[0m\n"
