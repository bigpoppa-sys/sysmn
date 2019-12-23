#!/bin/bash

SYS_CLI="/usr/local/bin/syscoin-cli -conf=/home/syscoin/.syscoin/syscoin.conf -datadir=/home/syscoin/.syscoin"

BANNED="/Satoshi:4.0.1/,/Satoshi:4.0.2/,/Satoshi:4.0.3/,/Satoshi:4.0.0/"

$SYS_CLI getpeerinfo | awk -F":" -v banned="$BANNED" -v syscli="$SYS_CLI" -- '
BEGIN {
    split(banned,BAN,",");
}
/\"id\"*/ {
    id=substr($2,2,length($2)-2);ID[id]=id;
}
/^....\"addr\"/ {
 if (substr($2,3,1)=="[") {
    sadr = substr($0,index($0,":"));
    start = index(sadr,"[");
    end = index(sadr,"]");
    IP[id]=substr(sadr,start,end-3);
  } else {
    IP[id]=substr($2,3);
  }
}
/\"subver\"*/ {
    s=length($1)+4;
    VER[id]=substr($0,s,(length($0)-s-1));
}
END {
    for (id in ID) {
	for (banned in BAN) {
            if(VER[id]==BAN[banned]) {
		system(syscli" setban "IP[id]" add");
	    }
	}
    }
}'

stop_syscoind(){
  echo "Stopping"
  sudo service syscoind stop
  clear
}

start_syscoind(){
  echo "Starting Syscoin"
  sudo service syscoind start     # start the service
  sudo systemctl enable syscoind  # enable at boot
  clear
}

remove_geth(){
	rm -rf /home/syscoin/.syscoin/geth
}

stop_syscoind
remove_geth
start_syscoind
