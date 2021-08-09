# 
# Sample curl command syntax to create an Event in your ServiceNow instance
#

curl "https://YOURINSTANCE.service-now.com/api/global/em/jsonv2" \
--request POST \
--header "Accept:application/json" \
--header "Content-Type:application/json" \
--data "{

   \"records\":
   [
     {
        \"description\": \"file system /var almost full on host demoui\",
        \"event_class\": \"Netcool Prod\",
        \"metric_name\": \"ITM_Linux_Filesystem\",
        \"node\": \"demoui\",
        \"resolution_state\": \"New\",
        \"resource\": \"/var\",
        \"severity\": \"4\",
        \"source\": \"IBM Netcool\",
        \"type\": \"Filesystem\",
        \"ci_type\": \"cmdb_ci_file_system\",
        \"message_key\": \"ITM_Linux_Filesystem:/var:demoui:6\",
        \"additional_info\": \
\"{ \
\\\"casdRoute\\\": \\\"APP_DCMTM\\\", \
\\\"casdRequired\\\": \\\"1\\\", \
\\\"notifDest\\\": \\\"APP_DCMTM@xyzcorp.com\\\", \
\\\"notifRequired\\\": \\\"1\\\", \
\\\"sn_ci_type\\\": \\\"cmdb_ci_file_system\\\", \
\\\"sn_name\\\": \\\"/dev/sda2\\\", \
\\\"name\\\": \\\"/dev/sda2\\\", \
\\\"xyz_application\\\": \\\"Documentum PR\\\", \
\\\"xyz_assignment_group\\\": \\\"Documentum Support\\\" \
}\"

   }
]
}" \
--user 'admin':’PASSWORD’
