[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$user = 'YOUR USER NAME'
$pass = 'THE USERS PASSWORD GOES HERE'

$pair = "$($user):$($pass)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
Authorization = $basicAuthValue
}

$recordsArray = @(
@{'source' = 'deleteme';
'event_class' = 'deleteme';
'node' = 'ftnode';
'metric_name' = 'ftdeleteme';
'severity' = '1';
'description' = 'Testing REST API in DEV';
'additional_info' = '"additional_content":"Welcome to the Event Management Course", "otherfield":"othervalue"'

}
)
$jsonArray = ConvertTo-Json -InputObject $recordsArray

$params = @{
'records' = $jsonArray
} | ConvertTo-Json

Invoke-RestMethod -Uri 'https://YOURINSTANCE.service-now.com/api/global/em/jsonv2' -Headers $Headers -Method POST -ContentType "application/json" -body $params
