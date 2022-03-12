#!/bin/bash

# Variables
duration='30d'
appid='c4aa9d22-bdfb-45d5-a2d8-asdasdasdas'
secret='y.~mk85k024-X8wtszxczxczxczxczxc-'
scope="https%3A%2F%2Fgraph.microsoft.com%2F%2Ffiles.readwrite.all%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fsites.readwrite.all%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fteam.readbasic.all"
header1="application/zip"
header2="application/x-www-form-urlencoded"
timestamp=$(($(date +%s)-25250)); t=$(date -d @${timestamp} '+%F')

#target names/itemids
names+="vm1|vm2|vm3|vm4|vm5|vm6|vm7|vm8|vm9|"
ids+="35845|35851|36293|36294|36295|36296|36297|35886|35892|36573|36574|36575|36576|36577|"
names+="vm1|vm2|vm3|vm4|vm5|vm6|vm7|vm8|vm9|"
ids+="36759|36766|36952|36955|36953|36957|36956|36958|36798|36806|37205|37210|37209|"

#download graph
IFS='|'; read -a name <<<"${names%?}"
IFS='|'; read -a id <<<"${ids%?}"
length=${#id[@]}
for (( i=0; i<${length}; i++ )); do
    wget --save-cookies="/tmp/zc_${timestamp}" --keep-session-cookies --post-data "name=$NAME&password=$PASS&enter=Sign+in" -O /dev/null -q "http://$ZBXIP/zabbix/index.php?login=1"
    wget --load-cookies="/tmp/zc_${timestamp}"  -O "${name[$i]}-${t}.png" -q "http://$ZBXIP/zabbix/chart3.php?items[0][itemid]=${id[$i]}&width=1280&from=now-${duration}&to=now"
    rm -f /tmp/zc_${timestamp}
done

#upload zip
zip zabbix.zip *.png
rm -f *.png

## Login
tkn=$(curl -sS -H "Content-Type: $header2" https://login.microsoftonline.com/$TENANT/oauth2/v2.0/token -d 'client_id='"${appid}"'&scope='"${scope}"'&client_secret='"${secret}"'&username=$USER&password=$PASS&grant_type=password' | jq '.access_token')

### Upload
curl -H "Content-type: $header1" -X PUT -d @zabbix.zip https://graph.microsoft.com/v1.0/me/drive/root:/zabbix-${t}-${duration}.zip:/content -H "Authorization: Bearer ${tkn//\"}"
