#!/bin/bash
# $1 = Azure storage account name 
# $2 = Azure storage account key 
# $3 = Azure file share name 
# $4 = Mountpoint path (required for multi-instance VMSS, else set to empty string) 

sudo bash -c 'echo "fs.file-max = 1048576" >> /etc/sysctl.conf'
sudo sysctl -p

if [ -d "/data/boomi" ] && [ -d "/data/export" ] && [ -d "/data/files" ] 
then
  echo "good"
else
    sudo mkdir -p /data/boomi && sudo mkdir /data/files && sudo mkdir /data/export && sudo chmod 777 /data && sudo chmod 777 /data/boomi && sudo chmod 777 /data/files && sudo chmod 777 /data/export
fi

if [ ! -d "/etc/smbcredentials" ]; then
sudo mkdir -p /etc/smbcredentials
fi
if [ ! -f "/etc/smbcredentials/$1.cred" ]; then
    sudo bash -c 'echo "username='$1'" >> /etc/smbcredentials/'$1'.cred'
    sudo bash -c 'echo "password='$2'" >> /etc/smbcredentials/'$1'.cred'
fi

sudo chmod 600 /etc/smbcredentials/$1.cred

#create the drive that is being mapped to if doesn't exist
if [ ! -d $4 ]; then
  echo "missing directory, creating $4"
  sudo mkdir -p $4
  sudo chmod 777 $4
fi

# Map storage account to drive if 4 parameters exist.
if [ ! -z $4 ]; then
  #added in code to check if the map data command is already in the fstab file
  MAPVALUE="//$1.file.core.windows.net/$3 $4 cifs nofail,vers=3.0,credentials=/etc/smbcredentials/$1.cred,dir_mode=0777,file_mode=0777,serverino" 
  if !( grep //etc/fstab -e "$MAPVALUE" ); then
    sudo echo $MAPVALUE  >> /etc/fstab 
    sudo echo "mappped $MAPVAULE"
  fi
fi 

sudo mount -a

sudo mkdir -p /opt/boomi
sudo mkdir -p /opt/boomi/local
sudo chmod -R 777 /opt/boomi/
sudo chmod -R 777 /opt/boomi/local
sudo chmod -R 777 /tmp
sudo mkdir -p /data 
sudo mkdir -p /data/boomi 
sudo mkdir -p /data/files 
sudo mkdir -p /data/export 
sudo chmod 777 /data 
sudo chmod 777 /data/boomi 
sudo chmod 777 /data/files 
sudo chmod 777 /data/export
sudo mkdir -p /tmp/fvrc 
sudo chmod 777 /tmp/fvrc

export INSTALL4J_JAVA_HOME=/data/boomi/jre

if [ -d "/data/boomi/lib" ] 
then
    sudo cp /data/container-launcher.jar /data/boomi/lib/container-launcher.jar
else
  echo "Boomi not installed, do nothing"
fi

#if [ -d "/data/boomi/bin" ] 
#then
#    sudo /data/boomi/bin/./atom start
#else
#  echo "Boomi not installed, do nothing"
#fi

if systemctl --all --type service | grep -q "boomi"
then
  echo "Boomi service already exists."
else    
  echo "Creating Boomi service..."

  sudo echo  "[Unit]
  Description=Dell Boomi [atomName]
  After=network.target
  RequiresMountsFor=[installDirMountPoint]
  [Service]
  Type=forking
  User=root
  ExecStart=/data/boomi/bin/atom start
  ExecStop=/data/boomi/bin/atom stop
  ExecReload=/data/boomi/bin/atom restart
  LimitAS=infinity
  LimitRSS=infinity
  LimitCORE=infinity
  LimitNOFILE=3048576
  Restart=always
  TimeoutSec=5min
  IgnoreSIGPIPE=no
  KillMode=process
  GuessMainPID=no
  [Install]
  WantedBy=multi-user.target" > /etc/systemd/system/boomi.service

  sudo systemctl daemon-reload
  sudo systemctl enable boomi.service
  sudo systemctl daemon-reload
fi

# Only start if we have boomi installed.
if [ -d "/data/boomi/bin" ] 
then
    echo "Starting Boomi service (if not already started)..."
    systemctl start boomi.service 
else
  echo "Boomi not installed, do nothing"
fi  
