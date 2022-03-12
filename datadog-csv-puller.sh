#!/bin/bash

# Variables
duration=30; d=$((${duration}*86400)); from=$(($(date +%s)-${d})); till=$(date +%s)
appid='c4aa9d22-bdfb-45d5-a2d8-asdasdasdas'
secret='y.~mk85k024-X8wtszxczxczxczxczxc-'
scope="https%3A%2F%2Fgraph.microsoft.com%2F%2Ffiles.readwrite.all%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fsites.readwrite.all%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fteam.readbasic.all"
timestamp=$(($(date +%s)-25250)); t=$(date -d @${timestamp} '+%Y-%m')
giofile="server-tvdc-${t}-${duration}days.csv"; giotemp="server-tvdc.csv"
gcpfile="server-gcp-${t}-${duration}days.csv"; gcptemp="server-gcp.csv"

#target itemids/names
#AGT-38+12
vnames+="vm1|vm2|vm3|vm4|vm5|vm6|vm7|vm8|vm9|"
vmetrics+="system.net.bytes_rcvd|system.disk.in_use|"
vmetrics+="system.cpu.idle|system.mem.pct_usable|"

#ITG-9
inames+="vm1|vm2|vm3|vm4|vm5|vm6|vm7|vm8|vm9|"
imetrics+="system.net.bytes_rcvd|system.disk.in_use|"
imetrics+="system.cpu.idle|system.mem.pct_usable|"

#retrieve data
IFS='|'; read -a vname <<<"${vnames%?}"
IFS='|'; read -a vmet <<<"${vmetrics%?}"
length=${#vname[@]}; length2=${#vmet[@]}
for (( i=0; i<${length}; i++ )); do for (( j=0; j<${length2}; j++ )); do if [[ ${j} < 2 ]]; then 
vm=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:${vmet[$j]}%7Bhost:${vname[$i]}%7D.rollup%28max%2C3600%29" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | max')
else vm=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:${vmet[$j]}%7Bhost:${vname[$i]}%7D.rollup%28min%2C3600%29" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | min'); fi
va=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:${vmet[$j]}%7Bhost:${vname[$i]}%7D" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | add/length')
vmavg+="$(printf "%.2f" ${va})|"; vmmax+="$(printf "%.2f" ${vm})|"
done; done
IFS='|'; read -a iname <<<"${inames%?}"
IFS='|'; read -a imet <<<"${imetrics%?}"
length=${#iname[@]}; length2=${#imet[@]}
for (( i=0; i<${length}; i++ )); do for (( j=0; j<${length2}; j++ )); do if [[ ${j} < 2 ]]; then 
im=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:${imet[$j]}%7Bhost:${iname[$i]}%7D.rollup%28max%2C3600%29" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | max')
else im=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:${imet[$j]}%7Bhost:${iname[$i]}%7D.rollup%28min%2C3600%29" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | min'); fi
ia=$(curl -sS "https://api.datadoghq.com/api/v1/query?from=${from}&to=${till}&query=avg:${imet[$j]}%7Bhost:${iname[$i]}%7D" -H "DD-API-KEY: $API" -H "DD-APPLICATION-KEY: $KEY" | jq '[.series[0].pointlist | flatten | .[] | tostring | select(contains(".")) | tonumber] | add/length')
inavg+="$(printf "%.2f" ${ia})|"; inmax+="$(printf "%.2f" ${im})|"
done; done

#create csv
vmcsv+="Hostname,Network-Avg(B/s),Network-Max(B/s),Disk-Avg(pct),Disk-Max(pct),"
vmcsv+="CPU-Avg(pct),CPU-Max(pct),Memory-Avg(pct),Memory-Max(pct)
"
incsv+="Hostname,Network-Avg(B/s),Network-Max(B/s),Disk-Avg(pct),Disk-Max(pct),"
incsv+="CPU-Avg(pct),CPU-Max(pct),Memory-Avg(pct),Memory-Max(pct)
"
IFS='|'; read -a va <<<"${vmavg%?}"; length1=${#va[@]}
IFS='|'; read -a vm <<<"${vmmax%?}";
IFS='|'; read -a ia <<<"${inavg%?}"; length2=${#ia[@]}
IFS='|'; read -a im <<<"${inmax%?}";
j=0;for (( i=0; i<${length1}; i++ )); do if [[ $((i%4)) == 0 ]]; then
vmcsv+="${vname[$j]},${va[$i]},${vm[$i]},${va[$i+1]},${vm[$i+1]},";((j++))
vmcsv+="$(echo "100-${va[$i+2]}" | bc),$(echo "100-${vm[$i+2]}" | bc),$(echo "100-(100*${va[$i+3]})" | bc),$(echo "100-(100*${vm[$i+3]})" | bc)
"
fi; done
j=0;for (( i=0; i<${length2}; i++ )); do if [[ $((i%4)) == 0 ]]; then
incsv+="${iname[$j]},${ia[$i]},${im[$i]},${ia[$i+1]},"${im[$i+1]},";((j++))
incsv+="$(echo "100-${ia[$i+2]}" | bc),$(echo "100-${im[$i+2]}" | bc),$(echo "100-(100*${ia[$i+3]})" | bc),$(echo "100-(100*${im[$i+3]})" | bc)
"
fi; done
printf "${vmcsv}" >> ${giofile}; printf "${incsv}" >> ${gcpfile} 
gcloud compute scp /home/admin/Test/${giofile} labghifari@lab-ghifari:/var/www/html/temp/${giotemp} --zone=asia-southeast2-a --project=project-lab
gcloud compute scp /home/admin/Test/${gcpfile} labghifari@lab-ghifari:/var/www/html/temp/${gcptemp} --zone=asia-southeast2-a --project=project-lab
