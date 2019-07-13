#!/bin/bash

# to run script simply paste
# bash <(curl -sL https://raw.githubusercontent.com/bigpoppa-sys/sysmn/master/sys-agent.sh)

# syscoin conf file
SYSCOIN_CONF=$(cat <<EOF
#rpc config
testnet=1
[test]
listen=1
daemon=1
server=1
port=18369
rpcport=18370
gethtestnet=1
addnode=54.190.239.153
addnode=52.40.171.92
rpcuser=u
rpcpassword=p
EOF
)

pause(){
  echo ""
  read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
  clear
}

update_system(){
  echo "$MESSAGE_UPDATE"
  # update package and upgrade Ubuntu
  sudo DEBIAN_FRONTEND=noninteractive apt -y update
  sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade
  sudo DEBIAN_FRONTEND=noninteractive apt -y autoremove
  clear
}

maybe_prompt_for_swap_file(){
  # Create swapfile if less than 8GB memory
  MEMORY_RAM=$(free -m | awk '/^Mem:/{print $2}')
  MEMORY_SWAP=$(free -m | awk '/^Swap:/{print $2}')
  MEMORY_TOTAL=$(($MEMORY_RAM + $MEMORY_SWAP))
  if [ $MEMORY_RAM -lt 3800 ]; then
      echo "You need to upgrade your server to 4 GB RAM."
       exit 1
  fi
  if [ $MEMORY_TOTAL -lt 7700 ]; then
      CREATE_SWAP="Y";
  fi
}

maybe_create_swap_file(){
  if [ "$CREATE_SWAP" = "Y" ]; then
    echo "Creating a 4GB swapfile..."
    sudo swapoff -a
    sudo dd if=/dev/zero of=/swap.img bs=1M count=4096
    sudo chmod 600 /swap.img
    sudo mkswap /swap.img
    sudo swapon /swap.img
    echo '/swap.img none swap sw 0 0' | sudo tee --append /etc/fstab > /dev/null
    sudo mount -a
    echo "Swapfile created."
    clear
  fi
}

install_ufw(){
  echo "$MESSAGE_UFW"
  sudo apt-get install ufw -y
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  sudo ufw allow 18369/tcp
  sudo ufw allow 30303/tcp
  yes | sudo ufw enable
  clear
}

install_dependencies(){
  echo "Install Depend"
  sudo apt-get update 
  sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev
  sudo apt install -y git
  sudo apt-get instal -y  software-properties-common
  sudo add-apt-repository -y ppa:bitcoin/bitcoin 
  sudo apt-get update -y  
  sudo apt-get install -y libdb4.8-dev libdb4.8++-dev
  clear
}

build_syscoin(){
  echo "Build"	
  git clone http://www.github.com/syscoin/syscoin 
  cd syscoin 
  git checkout dev-4.x
  git pull
  ./autogen.sh 
  ./configure
  make -j$(nproc)
  clear	
}

make_install() {
  echo "Make Install"
  # install the binaries to /usr/local/bin
  cd ~/syscoin
  sudo make install
  clear
}

create_conf(){
  echo "Creating Conf"
  sudo mkdir ~/.syscoin
  echo "$SYSCOIN_CONF" > ~/.syscoin/syscoin.conf
  clear
}

start_syscoind(){
	cd
	syscoind
}

pause
#system updates
update_system
maybe_prompt_for_swap_file
maybe_create_swap_file
install_ufw
install_dependencies

#install syscoin
build_syscoin
create_conf
make_install

#run
start_syscoind
