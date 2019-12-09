#!/usr/bin/env bash

#Automation of DKIM

#domain validation
dom_val(){
printf "What domain: "
while read domain; do
echo ${domain}
if [ -f /var/named/${domain}.db ]; then
        echo "valid doamin"
        break
else
        echo "invalid domain, try again"
        echo ""
        printf "What Domain: "
        continue

fi
done
}
read -p "1024 or 2048? " user_input;

if [ ${user_input} = 1024 ] || [ ${user_input} = 2048 ]
  then
   openssl genrsa -out /var/cpanel/domain_keys/private/${domain} ${user_input}
   openssl rsa -in /var/cpanel/domain_keys/private/${domain} -pubout -out /var/cpanel/domain_keys/public/${DOMAIN}
   echo "Add the following DKIM txt record: "
   echo "default._domainkey IN TXT \"v=DKIM1; k=rsa; p="$(awk '$0 !~ / KEY/{printf $0 }' /var/cpanel/domain_keys/public/${DOMAIN} )\"
 elif [ ${user_input} != 1024 ] || [ ${user_input} != 2048 ]
   then
    echo "Wrong key length." && return 1;
fi

echo "Backing up zone file...";
 sleep 2s
  cp -v /var/named/${DOMAIN}.db /var/named/${DOMAIN}.db.$(date +%F)
   echo "Zone file backed up.";

echo "Current SOA..."
  sleep 2s
    awk 'FNR == 5 {print $1}' /var/named/${DOMAIN}.db

#Set DKIM variable

DKIM=$(awk '$0 !~ / KEY/{printf $0 }' /var/cpanel/domain_keys/public/${DOMAIN})

echo "Adding to zone file..."
  sleep 2s

if [ $? = 0 ]
 then
   whmapi1 addzonerecord domain=${DOMAIN} name=default._domainkey class=IN ttl=14400 type=TXT txtdata="v=DKIM1; k=rsa; p=${DKIM}"
fi

echo "Check zone file for formatting errors.";
  sleep 1s

echo "New SOA..."
 sleep 2s
  awk 'FNR == 5 {print $1}' /var/named/${DOMAIN}.db

sleep 1s

  read -r -p "Edit zone file? [Y/n] " response
 response=${response,,} # tolower
if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]];
  then
    vim /var/named/${DOMAIN}.db
  else
    return 1;
fi
 dom_val