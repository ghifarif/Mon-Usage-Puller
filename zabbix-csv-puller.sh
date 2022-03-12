#!/bin/bash

# Variables
duration=30; d=$((${duration}*86400)); from=$(($(date +%s)-${d})); till=$(date +%s)
appid='c4aa9d22-bdfb-45d5-a2d8-asdasdasdas'
secret='y.~mk85k024-X8wtszxczxczxczxczxc-'
scope="https%3A%2F%2Fgraph.microsoft.com%2F%2Ffiles.readwrite.all%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fsites.readwrite.all%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fteam.readbasic.all"
timestamp=$(($(date +%s)-25250)); t=$(date -d @${timestamp} '+%Y-%m')
winfile="windows-server-${t}-${duration}days.csv"; wintemp="windows-server.csv"
linfile="linux-server-${t}-${duration}days.csv"; lintemp="linux-server.csv"

#target itemids/names
wids+="35845|35851|36293|36294|36295|36296|36297|"
wids+="35886|35892|36573|36574|36575|36576|36577|"
wnames+="vm1|vm2|vm3|vm4|vm5|vm6|vm7|vm8|vm9|"

lids+="36837|36844|37248|37253|37252|37256|37254|"
lids+="37399|37406|37740|37749|37745|37746|37743|"
lnames+="vm1|vm2|vm3|vm4|vm5|vm6|vm7|vm8|vm9|"

#data retrieval
IFS='|'; read -a wname <<<"${wnames%?}"
IFS='|'; read -a wid <<<"${wids%?}"
length=${#wid[@]}
j=0; for (( i=0; i<${length}; i++ )); do ((j++)); if [[ ${wid[$i]} != "-" ]]; then if [[ ${j} < 3 ]]; then 
wm=$(curl -sS -H "Content-Type: application/json" http://$ZBXIP/zabbix/api_jsonrpc.php -d '{"jsonrpc": "2.0","method": "trend.get","params": {"output": ["itemid","clock","value_max"],"itemids": ["'"${wid[$i]}"'"],"time_from":"'"${from}"'","time_till":"'"${till}"'","limit":"721"},"auth": "0845b1c6ccdf06d1882d515c1a0caf63","id": 1}' | jq '[.result[].value_max | tonumber] | max')
else wm=$(curl -sS -H "Content-Type: application/json" http://$ZBXIP/zabbix/api_jsonrpc.php -d '{"jsonrpc": "2.0","method": "trend.get","params": {"output": ["itemid","clock","value_min"],"itemids": ["'"${wid[$i]}"'"],"time_from":"'"${from}"'","time_till":"'"${till}"'","limit":"721"},"auth": "0845b1c6ccdf06d1882d515c1a0caf63","id": 1}' | jq '[.result[].value_min | tonumber] | min'); fi
wa=$(curl -sS -H "Content-Type: application/json" http://$ZBXIP/zabbix/api_jsonrpc.php -d '{"jsonrpc": "2.0","method": "trend.get","params": {"output": ["itemid","clock","value_avg"],"itemids": ["'"${wid[$i]}"'"],"time_from":"'"${from}"'","time_till":"'"${till}"'","limit":"721"},"auth": "0845b1c6ccdf06d1882d515c1a0caf63","id": 1}' | jq '[.result[].value_avg | tonumber] | add/length')
winavg+="$(printf "%.2f" ${wa})|"; winmax+="$(printf "%.2f" ${wm})|"
else winavg+="-|"; winmax+="-|"; fi; if [[ ${j} == 7 ]]; then j=0; fi
done
IFS='|'; read -a lname <<<"${lnames%?}"
IFS='|'; read -a lid <<<"${lids%?}"
length=${#lid[@]}
j=0; for (( i=0; i<${length}; i++ )); do ((j++)); if [[ ${lid[$i]} != "-" ]]; then if [[ ${j} < 3 ]]; then 
lm=$(curl -sS -H "Content-Type: application/json" http://$ZBXIP/zabbix/api_jsonrpc.php -d '{"jsonrpc": "2.0","method": "trend.get","params": {"output": ["itemid","clock","value_max"],"itemids": ["'"${lid[$i]}"'"],"time_from":"'"${from}"'","time_till":"'"${till}"'","limit":"721"},"auth": "0845b1c6ccdf06d1882d515c1a0caf63","id": 1}' | jq '[.result[].value_max | tonumber] | max')
else lm=$(curl -sS -H "Content-Type: application/json" http://$ZBXIP/zabbix/api_jsonrpc.php -d '{"jsonrpc": "2.0","method": "trend.get","params": {"output": ["itemid","clock","value_min"],"itemids": ["'"${lid[$i]}"'"],"time_from":"'"${from}"'","time_till":"'"${till}"'","limit":"721"},"auth": "0845b1c6ccdf06d1882d515c1a0caf63","id": 1}' | jq '[.result[].value_min | tonumber] | min'); fi
la=$(curl -sS -H "Content-Type: application/json" http://$ZBXIP/zabbix/api_jsonrpc.php -d '{"jsonrpc": "2.0","method": "trend.get","params": {"output": ["itemid","clock","value_avg"],"itemids": ["'"${lid[$i]}"'"],"time_from":"'"${from}"'","time_till":"'"${till}"'","limit":"721"},"auth": "0845b1c6ccdf06d1882d515c1a0caf63","id": 1}' | jq '[.result[].value_avg | tonumber] | add/length')
linavg+="$(printf "%.2f" ${la})|"; linmax+="$(printf "%.2f" ${lm})|"
else linavg+="-|"; linmax+="-|"; fi; if [[ ${j} == 7 ]]; then j=0; fi
done

#create csv
wincsv+="Hostname,CPU-Avg(pct),CPU-Max(pct),Memory-Avg(pct),Memory-Max(pct),C:Avg(pct),C:Max(pct),"
wincsv+="D:Avg(pct),D:Max(pct),W:Avg(pct),W:Max(pct),X:Avg(pct),X:Max(pct),Y:Avg(pct),Y:Max(pct)
"
lincsv+="Hostname,CPU-Avg(pct),CPU-Max(pct),Memory-Avg(pct),Memory-Max(pct),rhel-root-Avg(pct),rhel-root-Max(pct),rhel-backup-Avg(pct),rhel-backup-Max(pct),"
lincsv+="rhel-oracle-Avg(pct),rhel-oracle-Max(pct),rhel-oradata-Avg(pct),rhel-oradata-Max(pct),rhel-oraindex-Avg(pct),rhel-oraindex-Max(pct)
"
IFS='|'; read -a wa <<<"${winavg%?}"; length1=${#wa[@]}
IFS='|'; read -a wm <<<"${winmax%?}";
IFS='|'; read -a la <<<"${linavg%?}"; length2=${#la[@]}
IFS='|'; read -a lm <<<"${linmax%?}";
j=0;for (( i=0; i<${length1}; i++ )); do if [[ $((i%7)) == 0 ]]; then
wincsv+="${wname[$j]},${wa[$i]},${wm[$i]},${wa[$i+1]},${wm[$i+1]},$(echo "100-${wa[$i+2]}" | bc),$(echo "100-${wm[$i+2]}" | bc),$(echo "100-${wa[$i+3]}" | bc),$(echo "100-${wm[$i+3]}" | bc),";((j++))
wincsv+="$(echo "100-${wa[$i+4]}" | bc),$(echo "100-${wm[$i+4]}" | bc),$(echo "100-${wa[$i+5]}" | bc),$(echo "100-${wm[$i+5]}" | bc),$(echo "100-${wa[$i+6]}" | bc),$(echo "100-${wm[$i+6]}" | bc)
"
fi; done
j=0;for (( i=0; i<${length2}; i++ )); do if [[ $((i%7)) == 0 ]]; then
lincsv+="${lname[$j]},${la[$i]},${lm[$i]},${la[$i+1]},${lm[$i+1]},$(echo "100-${la[$i+2]}" | bc),$(echo "100-${lm[$i+2]}" | bc),$(echo "100-${la[$i+3]}" | bc),$(echo "100-${lm[$i+3]}" | bc),";((j++))
lincsv+="$(echo "100-${la[$i+4]}" | bc),$(echo "100-${lm[$i+4]}" | bc),$(echo "100-${la[$i+5]}" | bc),$(echo "100-${lm[$i+5]}" | bc),$(echo "100-${la[$i+6]}" | bc),$(echo "100-${lm[$i+6]}" | bc)
"
fi; done
printf "${wincsv}" >> ${winfile}; printf "${lincsv}" >> ${linfile} 
gcloud compute scp /home/admin/Test/${winfile} labghifari@lab-ghifari:/var/www/html/temp/${wintemp} --zone=asia-southeast2-a --project=project-lab
gcloud compute scp /home/admin/Test/${linfile} labghifari@lab-ghifari:/var/www/html/temp/${lintemp} --zone=asia-southeast2-a --project=project-lab
