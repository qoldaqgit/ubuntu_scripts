
wget ""
wget ""

sudo touch /etc/systemd/system/idrac-user.service /app/log.txt
sudo echo "[Unit]
Description=Runs the iDrac fan controller
[Service]
ExecStart=/app/iDrac.sh
[Install]
WantedBy=default.target
" >> /etc/systemd/system/idrac-user.service

sudo touch /etc/systemd/system/idrac-default.service
sudo echo "[Unit]
Description=Pre-Shutdown Processes
DefaultDependencies=no
Before=shutdown.target
# This works because it is installed in the target and will be
#   executed before the target state is entered
# Also consider kexec.target

[Service]
Type=oneshot
ExecStart=/app/pre-shutdown.sh  
# your path and filename

[Install]
WantedBy=halt.target reboot.target shutdown.target

" >> /etc/systemd/system/idrac-default.service

sudo systemctl enable idrac-default.service
sudo systemctl enable idrac-user.service
