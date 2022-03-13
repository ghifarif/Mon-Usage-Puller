This script automatically pull utilization data to be displayed in analytical platform (Redash localhost in my case).
Combine with orchestration such as Jenkins/Azure DevOps/AWS Pipeline for cycle pulling automatically.
![image](https://user-images.githubusercontent.com/101460772/158055509-5f423d8b-5cbd-4f58-8f78-9c6d097f29a1.png)
Can be used for similiar case to other monitoring tool, provided API is supported.

Refference used/related in this repo:
- [jq lib](https://stedolan.github.io/jq/)
- [gcloud sdk](https://cloud.google.com/sdk/gcloud)
- [Microsoft Graph API](https://docs.microsoft.com/en-us/graph/api/resources/azure-ad-overview?view=graph-rest-1.0)
- [Zabbix API](https://www.zabbix.com/documentation/current/en/manual/api)
- [Datadog API](https://docs.datadoghq.com/api/latest/)
