sudo apt updat && sudo apt upgrade -y
sudo apt install ssh

sudo echo "Include /etc/ssh/sshd_config.d/*.conf

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
KbdInteractiveAuthentication no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
# the setting of PermitRootLogin without-password.
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
UsePAM no

PrintMotd no

# Allow client to pass locale environment variables
#AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem	sftp	/usr/lib/openssh/sftp-server

# Applies the following settings only to users in the sftpgroup
Match Group sftpuser
# Restricts users to their home directories
    ChrootDirectory %h
# Allows password authentication
 PasswordAuthentication yes
#Prevents TCP port forwarding
 AllowTcpForwarding no
# Prevents TCP port forwarding
 X11Forwarding no
# Limits users to SFTP without shell access
 ForceCommand internal-sftp
" >| '/etc/ssh/sshd_config'

sudo systemctl restart sshd

sudo addgroup sftpuser

#Create user script
echo "
if [[ \$# -eq 1 ]]
then
sudo useradd -G sftpuser -d /srv/\$1 -s /sbin/nologin \$1
sudo mkdir -p /srv/\$1
sudo chown root:sftpuser /srv/\$1
sudo chmod 755 /srv/\$1
sudo mkdir -p /srv/\$1/in
sudo chown \$1:sftpuser /srv/\$1/in
sudo chmod 771 /srv/\$1/in
sudo mkdir -p /srv/\$1/out
sudo chown \$1:sftpuser /srv/\$1/out
sudo chmod 771 /srv/\$1/out

echo "Enter password for user $1"
sudo passwd \$1
else 
echo \"Please provide username\"
fi
" >| 'sftpuser.sh'

#Create Admin Script
echo "
if [[ \$# -eq 1 ]]
then
sudo useradd -G sftpuser -d /srv/ -s /sbin/nologin \$1
echo "Enter password for admin $1"
sudo passwd \$1
else 
echo \"Please provide admin username\"
fi
" >| 'sftpadmin.sh'
echo "Create a Admin with command: sudo bash sftpadmin.sh [admin-username]"
echo "Create a user with command: sudo bash sftpuser.sh [username]"
