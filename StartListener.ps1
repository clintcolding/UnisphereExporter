[CmdletBinding()]
param (
    #---- The Web Server listening port ----#
    [int]$Port = 9183,
    #---- The path to a JSON file containing metrics to collect ----#
    [string]$MetricPath
)
#---- Verify required modules are imported ----#
try {
    if (!(Get-Module Polaris)) {
        Import-Module Polaris
    }
    if (!(Get-Module UnisphereExporter)) {
        Import-Module UnisphereExporter
    }
}
catch {
    Write-Error -Message "Failed to import required module: $_"
}

#---- Create Polaris Route ----#
New-PolarisGetRoute -Path "/metrics" -Force -Scriptblock {
    #---- Get metrics defined in $MetricPath ----#
    try {
        if ($MetricPath)  {$data = Get-Metrics -MetricPath $MetricPath}
        if (!$MetricPath) {$data = Get-Metrics}
    }
    catch {
        $content = $_
    }

    #---- Convert the metrics into Prometheus format ----#
    try {
        if ($data) {
            $metricdata = @()
            foreach ($i in $data) {
                $metricdata += "$($i.name)" + "{" + "$($i.label)" + "}" + " " + "$($i.value)"
            }
            $content = $metricdata -join "`n" | Out-String
            #---- Replace carriage returns and line feeds with just line feeds (\n) ----#
            $content = $content.Replace("`r`n","`n")
        }
        else {
            $content = "No metrics returned!"
        }
    }
    catch {
        $content = $_
    }

    #---- Serve metrics in plain text format ----#
    $Response.SetContentType("text/plain; version=0.0.4; charset=utf-8")
    $Response.Send($content)
}

#---- Start the Polaris Web Server on the defined port ----#
Start-Polaris -Port $Port

#---- Continue running the Web Server until stopped ----#
while($true) {
    Start-Sleep -Milliseconds 10
}
