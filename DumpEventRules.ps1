#$allrules=Get-Content -Raw .\AllEventRules.json | ConvertFrom-Json
# Define clear text string for username and password
[string]$userName = 'admin'
[string]$userPassword = 'YOURPASSWORD'

# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
$allrules=Invoke-WebRequest -Uri "https://YOURINSTANCE.service-now.com/api/now/table/em_match_rule" -Credential $credObject | ConvertFrom-Json

$allComposeFields=Invoke-WebRequest -Uri "https://YOURINSTANCE.service-now.com/api/now/table/em_compose_field" -Credential $credObject | ConvertFrom-Json

# table holding alert management rules: em_alert_management_rule
# column: alert_filter

$fullString = "<html><style>
table {
    width: 100%;
    border: 1px solid #000;
  }
  td {
    border: 1px solid #000;
}
  th.left {
    width: 15%
  }
  th.middle {
    width: 85%; 
  }
  h1 {
    background-color:lightblue;
  }
  </style>
  <body>
    <table>
        <thead>
            <tr>
                <th class='left'></th>
                <th class='middle'></th>
            </tr>
    </thead>
    ";
$oneFilterString = "";
$oneTransformString = "";
foreach ($rule in $allrules.result) {
    Add-Member -InputObject $rule -NotePropertyName json_filter -NotePropertyvalue $($rule.simple_filter|ConvertFrom-Json);
    Add-Member -InputObject $rule -NotePropertyName json_event_data -NotePropertyvalue $($rule.event_data|ConvertFrom-Json);
    
    $oneFilterString = ("<tr><td colspan=2><h1>" + $rule.name + "</h1></td></tr>");
    $oneFilterString =  ($oneFilterString + "<tr>
    <td><h2>Filter:</h2></td>
    <td><code>Source = " + $rule.event_class);
    for ($i = 0; $i -lt $rule.json_filter.subpredicates[0].subpredicates.Count; $i++) {
        $topcombination=$rule.json_filter.subpredicates[0].compound_type.ToUpper();
        if ($i -eq 0) {
            $oneFilterString = ($oneFilterString + " AND</BR>(");
        } else {
            $oneFilterString = ($oneFilterString + "");
        }
        for ($j = 0; $j -lt $rule.json_filter.subpredicates[0].subpredicates[$i].subpredicates.Count; $j++) {
            if ($j -eq 0) {
                $oneFilterString = $oneFilterString + "(";
            }
            $oneFilterString = ($oneFilterString + $rule.json_filter.subpredicates[0].subpredicates[$i].subpredicates[$j].field.name + " " +
                $rule.json_filter.subpredicates[0].subpredicates[$i].subpredicates[$j].operator.name + " " + 
                $rule.json_filter.subpredicates[0].subpredicates[$i].subpredicates[$j].field.value)
           
            if ($j -lt ($rule.json_filter.subpredicates[0].subpredicates[$i].subpredicates.Count - 1)) {
                $oneFilterString = $oneFilterString + " " + $rule.json_filter.subpredicates[0].subpredicates[$i].compound_type.ToUpper() + "</BR>";
            }
            
            if ($j -eq ($rule.json_filter.subpredicates[0].subpredicates[$i].subpredicates.Count - 1)) {
                $oneFilterString = ($oneFilterString + ")");
            } 
        }
        if ($i -lt ($rule.json_filter.subpredicates[0].subpredicates.Count - 1)) {
            $oneFilterString = ($oneFilterString + " " + $topcombination + "</BR>");
        } else {
            $oneFilterString = ($oneFilterString + ")");
            $fullString = ($fullString + $oneFilterString)
        }
        
        
    }
    if ($rule.json_filter.subpredicates[0].subpredicates.Count -eq 0) {
        # this is the case where the filter is just Source = some_string
        $fullstring = ($fullstring + $oneFilterString)
    }
    $fullString = ($fullString + "</code></td></tr>");

    # now build the HTML to display the Transform and Compose Alert Output tab information
    # fun fact: the composed field expressions are stored in the em_compose_field table
    # where the 
    # "match_rule" field is a reference to the sys_id of the associated Event Rule
    # "field" is the name of the field in the Alert that we're composing and
    # "composition" is the composition of the field (e.g. "${resource}:${secondpart}")
    #
    #  Wow. So now I see why Event Rules with node = <blank> don't get processed correctly in update sets:
    #  for a rule, if you set field = ${field}  (same field name on left and right), then there's no stinkin
    #  entry in the em_compose_field table for that rule (!). Really. So I guess the logic I need to
    #  employ is:
    #
    #  for an Event Rule, get all compose fields and use those mappings.
    #  for any remaining fields, set field = ${field} in my output
    #

    $oneTransformString = "";
    
    for ($i = 0; $i -lt $rule.json_event_data.additionalInfoFields.Count; $i++) {
        # These are the new fields created by parsing existing fields
        if ($rule.json_event_data.additionalInfoFields[$i].regex -ne "") {
            if ($oneTransformString -eq "") {
                $oneTransformString = "<tr>
                <td colspan=2><h2>Transform info</h2></td>
            </tr>";
            }
            # This means that the field is being parsed to create other fields
            # that list of new fields is in mapping[x].fieldToMap.name
            $oneTransformString = ($oneTransformString + "<tr><td><B>Parsed field: </B></td><td>" + $rule.json_event_data.additionalInfoFields[$i].name + "</B></td></tr>");
            $oneTransformString = ($oneTransformString + "<tr><td><B>Regex: </B></td><td>" + $rule.json_event_data.additionalInfoFields[$i].regex + "</td></tr>");
            $oneTransformString = ($oneTransformString + "<tr><td><B>Mapped fields: </B></td><td>");
            for ($j = 0; $j -lt $rule.json_event_data.additionalInfoFields[$i].mapping.Count; $j++) {
                $oneTransformString = ($oneTransformString + $rule.json_event_data.additionalInfoFields[$i].mapping[$j].fieldToMap.name + "</BR>");
            }
            $oneTransformString = ($oneTransformString + "</td></tr>");
        }
    }


    for ($i = 0; $i -lt $rule.json_event_data.rawFields.Count; $i++) {
        # These are the new fields created by parsing existing fields
        if ($rule.json_event_data.rawFields[$i].regex -ne "") {
            if ($oneTransformString -eq "") {
                $oneTransformString = "<tr>
                <td colspan=2><h2>Transform info</h2></td>
                </tr>";
            }
            # This means that the field is being parsed to create other fields
            # that list of new fields is in mapping[x].fieldToMap.name
            $oneTransformString = ($oneTransformString + "<tr><td><B>Parsed field: </B></td><td>" + $rule.json_event_data.rawFields[$i].name + "</B></td></tr>");
            $oneTransformString = ($oneTransformString + "<tr><td><B>Regex: </B></td><td>" + $rule.json_event_data.rawFields[$i].regex + "</td></tr>");
            $oneTransformString = ($oneTransformString + "<tr><td><B>Mapped fields: </B></td><td>");
            for ($j = 0; $j -lt $rule.json_event_data.rawFields[$i].mapping.Count; $j++) {
                $oneTransformString = ($oneTransformString + $rule.json_event_data.rawFields[$i].mapping[$j].fieldToMap.name + "</BR>");
            }
            $oneTransformString = ($oneTransformString + "</td></tr>");
        }
    }
    
    $fullString = ($fullString + $oneTransformString);

    $oneRuleFieldsString = "<tr><td colspan=2><h2>Custom Compose Fields</h2></td></tr>";
    $thisRuleFields = $allComposeFields.result.where{$_.match_rule.value -eq $rule.sys_id};
    foreach ($field in $thisRuleFields) {
        $oneRuleFieldsString = ($oneRuleFieldsString + "<tr><td><B>" + $field.field + "</B> : </td><td>" + $field.composition + "</td></tr>");
    }
    if ($oneRuleFieldsString -eq "<tr><td colspan=2><h2>Custom Compose Fields</h2></td></tr>") {
        # do not update $fullString
    } else {
        $fullString = ($fullString + $oneRuleFieldsString);
    }

}
$fullString = ($fullString + "</table></body></html>");
$fullString > DumpEventRules.html;



