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
length=${#vname[@]}; length2=${#vdev[@]}
for (( i=0; i<${length}; i++ )); do for (( j=0; j<${length2}; j++ )); do
vm=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:system.disk.in_use%7Bhost:${vname[$i]}%2Cdevice:${vdev[$j]}%7D.rollup%28max%2C3600%29" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | max')
va=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:system.disk.in_use%7Bhost:${vname[$i]}%2Cdevice:${vdev[$j]}%7D" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | add/length')
vmavg+="$(printf "%.2f" ${va})|"; vmmax+="$(printf "%.2f" ${vm})|"
done; done
IFS='|'; read -a iname <<<"${inames%?}"
IFS='|'; read -a idev <<<"${idevices%?}"
length=${#iname[@]}; length2=${#idev[@]}
for (( i=0; i<${length}; i++ )); do for (( j=0; j<${length2}; j++ )); do
im=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:system.disk.in_use%7Bhost:${iname[$i]}%2Cdevice:${idev[$j]}%7D.rollup%28max%2C3600%29" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | max')
ia=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:system.disk.in_use%7Bhost:${iname[$i]}%2Cdevice:${idev[$j]}%7D" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | add/length')
inavg+="$(printf "%.2f" ${ia})|"; inmax+="$(printf "%.2f" ${im})|"
done; done

#create csv
vmcsv+="Hostname,C:Avg(pct),C:Max(pct),D:Avg(pct),D:Max(pct),E:Avg(pct),E:Max(pct),F:Avg(pct),F:Max(pct),G:Avg(pct),G:Max(pct),"
vmcsv+="H:Avg(pct),H:Max(pct),V:Avg(pct),V:Max(pct),W:Avg(pct),W:Max(pct),X:Avg(pct),X:Max(pct),Y:Avg(pct),Y:Max(pct),
"
incsv+="Hostname,rhel-root-Avg(pct),rhel-root-Max(pct),rhel-backup-Avg(pct),rhel-backup-Max(pct),rhel-oracle-Avg(pct),"
incsv+="rhel-oracle-Max(pct),rhel-oradata-Avg(pct),rhel-oradata-Max(pct),rhel-oraindex-Avg(pct),rhel-oraindex-Max(pct),"
incsv+="sap-rootvg-Avg(pct),sap-rootvg-Max(pct),sap-oraclevg-Avg(pct),sap-oraclevg-Max(pct),"
incsv+="sap-ecccivg-Avg(pct),sap-ecccivg-Max(pct),sap-eccappvg-Avg(pct),sap-eccappvg-Max(pct),
"
IFS='|'; read -a va <<<"${vmavg%?}"; length1=${#va[@]}
IFS='|'; read -a vm <<<"${vmmax%?}";
IFS='|'; read -a ia <<<"${inavg%?}"; length2=${#ia[@]}
IFS='|'; read -a im <<<"${inmax%?}";
j=0;for (( i=0; i<${length1}; i++ )); do if [[ $((i%10)) == 0 ]]; then
vmcsv+="${vname[$j]},$(echo "100*${va[$i]}" | bc),$(echo "100*${vm[$i]}" | bc),$(echo "100*${va[$i+1]}" | bc),$(echo "100*${vm[$i+1]}" | bc),";((j++))
vmcsv+="$(echo "100*${va[$i+2]}" | bc),$(echo "100*${vm[$i+2]}" | bc),$(echo "100*${va[$i+3]}" | bc),$(echo "100*${vm[$i+3]}" | bc),$(echo "100*${va[$i+4]}" | bc),$(echo "100*${vm[$i+4]}" | bc),"
vmcsv+="$(echo "100*${va[$i+5]}" | bc),$(echo "100*${vm[$i+5]}" | bc),$(echo "100*${va[$i+6]}" | bc),$(echo "100*${vm[$i+6]}" | bc),$(echo "100*${va[$i+7]}" | bc),$(echo "100*${vm[$i+7]}" | bc),"
vmcsv+="$(echo "100*${va[$i+8]}" | bc),$(echo "100*${vm[$i+8]}" | bc),$(echo "100*${va[$i+9]}" | bc),$(echo "100*${vm[$i+9]}" | bc)
"
fi; done
j=0;for (( i=0; i<${length2}; i++ )); do if [[ $((i%9)) == 0 ]]; then
incsv+="${iname[$j]},$(echo "100*${ia[$i]}" | bc),$(echo "100*${im[$i]}" | bc),$(echo "100*${ia[$i+1]}" | bc),$(echo "100*${im[$i+1]}" | bc),";((j++))
incsv+="$(echo "100*${ia[$i+2]}" | bc),$(echo "100*${im[$i+2]}" | bc),$(echo "100*${ia[$i+3]}" | bc),$(echo "100*${im[$i+3]}" | bc),$(echo "100*${ia[$i+4]}" | bc),$(echo "100*${im[$i+4]}" | bc),"
incsv+="$(echo "100*${ia[$i+5]}" | bc),$(echo "100*${im[$i+5]}" | bc),$(echo "100*${ia[$i+6]}" | bc),$(echo "100*${im[$i+6]}" | bc),$(echo "100*${ia[$i+7]}" | bc),$(echo "100*${im[$i+7]}" | bc),"
incsv+="$(echo "100*${ia[$i+8]}" | bc),$(echo "100*${im[$i+8]}" | bc)
"
fi; done
printf "${vmcsv}" >> ${winfile}; printf "${incsv}" >> ${linfile} 
gcloud compute scp /home/admin/Test/${winfile} labghifari@lab-ghifari:/var/www/html/temp/${wintemp} --zone=asia-southeast2-a --project=project-lab
gcloud compute scp /home/admin/Test/${linfile} labghifari@lab-ghifari:/var/www/html/temp/${lintemp} --zone=asia-southeast2-a --project=project-lab
