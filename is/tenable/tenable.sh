#!/bin/bash
key="$1"
port="$2"
groups="$3"
name="$4"

echo "=== Nessus agent instalaltion process ==="

source /etc/os-release 
source /etc/os-release | echo "$NAME"
source /etc/os-release | echo "$NAME"


if [[ "$NAME" == "Ubuntu" ]]
then
echo "Creating temporary directory to install nessus agent in Ubuntu..."
sudo mkdir /home/nessus

echo "Downloading nessus agent application..."

sudo curl https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/20114/download?i_agree_to_tenable_license_agreement=true -o /home/nessus/NessusAgent-10.4.1-ubuntu1404_amd64.deb

echo "Installing nessus agent application..."
cd /home/nessus
sudo dpkg -i NessusAgent-10.4.1-ubuntu1404_amd64.deb && sudo /opt/nessus_agent/sbin/nessuscli  agent link --key="$key" --cloud --port="$port" --groups="$groups" --name="$name"
sudo rm NessusAgent-10.4.1-ubuntu1404_amd64.deb
cd
sudo rmdir /home/nessus

else

echo "Creating temporary directory to install nessus agent in REDHAT..."
sudo mkdir /home/nessus

echo "Downloading nessus agent application..."

sudo curl https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/20107/download?i_agree_to_tenable_license_agreement=true -o /home/nessus/NessusAgent-10.4.1-es7.x86_64.rpm

echo "Installing nessus agent application..."
cd /home/nessus
sudo rpm -ivh NessusAgent-10.4.1-es7.x86_64.rpm && /opt/nessus_agent/sbin/nessuscli agent link --groups="$groups" --cloud --key="$key" --name="$name" --port="$port"
sudo rm NessusAgent-10.4.1-es7.x86_64.rpm
cd
sudo rmdir /home/nessus
	
fi




