function Get-Metrics {
    [CmdletBinding()]

    param(
        #---- The path to a JSON file containing metrics to collect ----#
        [Parameter(Position=0)]
        [string]$MetricPath = "$PSScriptRoot\Config\metrics.json"
    )

    begin {
        #---- Import config ----#
        $config = Get-Content "$PSScriptRoot\Config\config.json" | ConvertFrom-Json

        #---- Force TLS 1.2 ----#
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        #---- Bypass SSL Checks ----#
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }

    process {
        $metrics = @()

        #---- Build basic auth request header ----#
        $credPair = "$($config.username):$($config.password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{Authorization = "Basic $encodedCredentials"}
        
        #---- Define metrics ----#
        $resources = Get-Content $MetricPath | ConvertFrom-Json

        foreach ($resource in $resources) {
            #---- Gather required resource ID's ----#
            $ids = Get-ResourceID -Resource $resource.resource

            #---- Build static request body ----#
            $data = @{}
            $data["symmetrixId"] = "$($config.symmetrixId)"
            #---- Set start date to now, minus 15 minutes, convert to UNIX ----#
            $data["startDate"] = ([int][double]::Parse((Get-Date (get-date).AddMinutes(-15).touniversaltime() -UFormat %s)) * 1000)
            #---- Set start date to now, convert to UNIX ----#
            $data["endDate"] = ([int][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s)) * 1000)
            $data["metrics"] = @($($resource.metrics))
            
            #---- Build static request Uri ----#
            $uri = "https://$($config.endpoint):$($config.port)/univmax/restapi/performance/$($resource.resource)/metrics"
            
            #---- If ID's were returned, gather metrics for each ID ----#
            if ($ids) {
                foreach ($id in $ids) {
                    $resourcename = $resource.resource.Replace(($resource.resource.substring(0,1)),(([string]$resource.resource[0]).ToLower()))
                    $data["$($resourcename)Id"] = $id
                    $body = ConvertTo-Json $data
                    try {
                        $request = Invoke-WebRequest -UseBasicParsing -Method Post -Body $body -uri $uri -Headers $headers -ContentType application/json
                    }
                    catch {}
                    #---- Select latest value of each metric ----#
                    $latest = $request | ConvertFrom-Json
                    $m = $latest.resultList.result | Sort-Object -Property timestamp -Descending | Select-Object -First 1
                      #---- Build output object for each metric, excluding timestamp property ----#
                    foreach ($metric in ($m.PSObject.Properties | Select -Expand Name | Where-Object {$_ -ne "timestamp"})) {
                        $metrics += [PSCustomObject]@{
                            Name = "vmax_$($resource.resource)_$metric"
                            Value = $m."$metric"
                            Label = $resource.resource + "Id=" + $id
                        }
                    }
                }
            }

            #---- If ID's were not returned, gather metrics for resource ----#
            if (!$ids) {
                $body = ConvertTo-Json $data
                try {
                    $request = Invoke-WebRequest -UseBasicParsing -Method Post -Body $body -uri $uri -Headers $headers -ContentType application/json
                }
                catch {}
                #---- Select latest value of each metric ----#
                $latest = $request | ConvertFrom-Json
                $m = $latest.resultList.result | Sort-Object -Property timestamp -Descending | Select-Object -First 1
                #---- Build output object for each metric, excluding timestamp property ----#
                foreach ($metric in ($m.PSObject.Properties | Select -Expand Name | Where-Object {$_ -ne "timestamp"})) {
                    $metrics += [PSCustomObject]@{
                        Name = "vmax_$($resource.resource)_$metric"
                        Value = $m."$metric"
                        Label = $resource.resource + "Id=" + $config.symmetrixId
                    }
                }
            }
        }

        #---- Output metrics ----#
        $metrics
    }

    end {
    }
}

function Get-ResourceID {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string]$Resource
    )
    
    begin {
        #---- Import config ----#
        $config = Get-Content "$PSScriptRoot\Config\config.json" | ConvertFrom-Json

        #---- Force TLS 1.2 ----#
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        #---- Bypass SSL Checks ----#
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }
    
    process {
        #---- Build basic auth request header ----#
        $credPair = "$($config.username):$($config.password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{Authorization = "Basic $encodedCredentials"}

        #---- Build request body ----#
        $body = @{}
        $body["symmetrixId"] = "$($config.symmetrixId)"
        $uri = "https://$($config.endpoint):$($config.port)/univmax/restapi/performance/$resource/keys"
        try {
            $request = Invoke-WebRequest -UseBasicParsing -Method Post -Body (ConvertTo-Json $body) -Uri $uri -Headers $headers -ContentType application/json
        }
        catch {}

        #---- Return IDs ----#
        if ($request) {
            $ids = ConvertFrom-Json $request
            $ids."$($Resource)Info"."$($Resource)Id"
        }
    }
    
    end {
    }
}