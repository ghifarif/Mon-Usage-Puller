#!/bin/bash

# Variables
duration=30; d=$((${duration}*86400)); from=$(($(date +%s)-${d})); till=$(date +%s)
appid='c4aa9d22-bdfb-45d5-a2d8-asdasdasdas'
secret='y.~mk85k024-X8wtszxczxczxczxczxc-'
scope="https%3A%2F%2Fgraph.microsoft.com%2F%2Ffiles.readwrite.all%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fsites.readwrite.all%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fteam.readbasic.all"
timestamp=$(($(date +%s)-25250)); t=$(date -d @${timestamp} '+%Y-%m')
winfile="windows-disk-${t}-${duration}days.csv"; wintemp="windows-disk.csv"
linfile="linux-disk-${t}-${duration}days.csv"; lintemp="linux-disk.csv"

#target itemids/names
#AGT-38+12
vnames+="vm1|vm2|vm3|vm4|vm5|vm6|vm7|vm8|vm9|"
vdevices+="c:|d:|e:|f:|g:|"
vdevices+="h:|v:|w:|x:|y:|"

#ITG-9
inames+="vm1|vm2|vm3|vm4|vm5|vm6|vm7|vm8|vm9|"
idevices+="%2Fdev%2Fmapper%2Frhel%2Droot|%2Fdev%2Fmapper%2Frhel%2Dbackup|%2Fdev%2Fmapper%2Frhel%2Doracle|"
idevices+="%2Fdev%2Fmapper%2Frhel%2Dorad*|%2Fdev%2Fmapper%2Frhel%2Dorai*|%2Fdev%2Fmapper%2Fsystem%2Dro*|"
idevices+="%2Fdev%2Fmapper%2Foradata*|%2Fdev%2Fmapper%2Feccci*|%2Fdev%2Fmapper%2Feccapp*|"

#retrieve data
IFS='|'; read -a vname <<<"${vnames%?}"
IFS='|'; read -a vdev <<<"${vdevices%?}"
length1=${#vname[@]}; length2=${#vdev[@]}
for (( i=0; i<${length1}; i++ )); do for (( j=0; j<${length2}; j++ )); do 
vchart+="$(curl -sS "https://api.datadoghq.com/api/v1/graph/snapshot?start=${from}&end=${till}&metric_query=avg:system.disk.in_use%7Bhost:${vname[$i]}%2Cdevice:${vdev[$j]}%7D" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '.snapshot_url')|"
done; done
IFS='|'; read -a iname <<<"${inames%?}"
IFS='|'; read -a idev <<<"${idevices%?}"
length3=${#iname[@]}; length4=${#idev[@]}
for (( i=0; i<${length3}; i++ )); do for (( j=0; j<${length4}; j++ )); do 
ichart+="$(curl -sS "https://api.datadoghq.com/api/v1/graph/snapshot?start=${from}&end=${till}&metric_query=avg:system.disk.in_use%7Bhost:${iname[$i]}%2Cdevice:${idev[$j]}%7D" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '.snapshot_url')|"
done; done

#download graph
IFS='|'; read -a vc <<<"${vchart%?}"
k=0; for (( i=0; i<${length1}; i++ )); do for (( j=0; j<${length2}; j++ )); do 
    wget -O "${vname[$i]}-${vdev[$j]}-${t}.png" -q "${vc[$k]//\"}"; ((k++))
done; done
IFS='|'; read -a ic <<<"${ichart%?}"
k=0; for (( i=0; i<${length3}; i++ )); do for (( j=0; j<${length4}; j++ )); do 
    wget -O "${iname[$i]}-${idev[$j]}-${t}.png" -q "${ic[$k]//\"}"; ((k++))
done; done

#upload zip
zip datadog.zip *.png
rm -f *.png

## Login
tkn=$(curl -sS -H "Content-Type: $header2" https://login.microsoftonline.com/$TENANT/oauth2/v2.0/token -d 'client_id='"${appid}"'&scope='"${scope}"'&client_secret='"${secret}"'&username=$USER&password=$PASS&grant_type=password' | jq '.access_token')

### Upload
curl -H "Content-type: $header1" -X PUT -d @datadog.zip https://graph.microsoft.com/v1.0/me/drive/root:/datadog-${t}-${duration}.zip:/content -H "Authorization: Bearer ${tkn//\"}"
