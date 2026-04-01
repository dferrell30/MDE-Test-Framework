#requires -Version 5.1
Set-StrictMode -Version Latest

$script:Results = @()
$script:BasePath = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$script:LogDir = Join-Path $script:BasePath 'logs'
$script:LogFile = $null

function Initialize-MDEFramework {
    if (-not (Test-Path -LiteralPath $script:LogDir)) {
        New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null
    }

    if (-not $script:LogFile) {
        $script:LogFile = Join-Path $script:LogDir ("MDE-TestLog_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
        New-Item -ItemType File -Path $script:LogFile -Force | Out-Null
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO','WARN','ERROR','PASS')]
        [string]$Level = 'INFO'
    )

    Initialize-MDEFramework

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $script:LogFile -Value $line
}

function Add-Result {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Details
    )

    $item = [PSCustomObject]@{
        TestName = $Name
        Status   = $Status
        Details  = $Details
        Time     = Get-Date
    }

    $script:Results += $item

    $level = switch ($Status) {
        'Passed'  { 'PASS' }
        'Warning' { 'WARN' }
        'Failed'  { 'ERROR' }
        default   { 'INFO' }
    }

    Write-Log -Message "$Name | $Status | $Details" -Level $level
}

function Test-DefenderService {
    try {
        $svc = Get-Service -Name 'Sense' -ErrorAction Stop
        if ($svc.Status -eq 'Running') {
            Add-Result 'Defender Sensor' 'Passed' 'Microsoft Defender for Endpoint sensor service is running.'
        }
        else {
            Add-Result 'Defender Sensor' 'Failed' "Sense service found, but status is $($svc.Status)."
        }
    }
    catch {
        Add-Result 'Defender Sensor' 'Failed' $_.Exception.Message
    }
}

function Test-AVStatus {
    try {
        $status = Get-MpComputerStatus -ErrorAction Stop

        $details = "RealtimeProtection={0}; AntivirusEnabled={1}; AMServiceEnabled={2}" -f `
            $status.RealTimeProtectionEnabled,
            $status.AntivirusEnabled,
            $status.AMServiceEnabled

        if ($status.RealTimeProtectionEnabled -and $status.AntivirusEnabled) {
            Add-Result 'AV Status' 'Passed' $details
        }
        else {
            Add-Result 'AV Status' 'Warning' $details
        }
    }
    catch {
        Add-Result 'AV Status' 'Failed' $_.Exception.Message
    }
}

function Test-ASR {
    try {
        $pref = Get-MpPreference -ErrorAction Stop
        $rules = @($pref.AttackSurfaceReductionRules_Ids)

        if ($null -ne $rules -and $rules.Count -gt 0) {
            Add-Result 'ASR Rules' 'Passed' "$($rules.Count) ASR rule(s) configured."
        }
        else {
            Add-Result 'ASR Rules' 'Warning' 'No ASR rules configured on this endpoint.'
        }
    }
    catch {
        Add-Result 'ASR Rules' 'Failed' $_.Exception.Message
    }
}

function Test-EICAR {
    $file = Join-Path $env:TEMP 'eicar.com.txt'

    try {
        if (Test-Path -LiteralPath $file) {
            Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
        }

        Invoke-WebRequest -Uri 'https://secure.eicar.org/eicar.com.txt' -OutFile $file -ErrorAction Stop

        Start-Sleep -Seconds 5

        $threat = $null
        try {
            $threat = Get-MpThreatDetection -ErrorAction Stop | Where-Object {
                $_.Resources -match 'eicar' -or $_.ThreatName -match 'eicar'
            }
        }
        catch {
        }

        if ($threat) {
            Add-Result 'EICAR Test' 'Passed' 'Defender detected EICAR.'
        }
        elseif (-not (Test-Path -LiteralPath $file)) {
            Add-Result 'EICAR Test' 'Passed' 'EICAR file was removed or quarantined.'
        }
        else {
            Add-Result 'EICAR Test' 'Warning' 'EICAR file still exists. Check Defender policy, exclusions, or delayed remediation.'
        }
    }
    catch {
        $msg = $_.Exception.Message
        if ($msg -match 'virus|malware|threat|denied|forbidden') {
            Add-Result 'EICAR Test' 'Passed' "Download blocked as expected: $msg"
        }
        else {
            Add-Result 'EICAR Test' 'Warning' $msg
        }
    }
    finally {
        if (Test-Path -LiteralPath $file) {
            Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
        }
    }
}

function Test-EDR {
    try {
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('Write-Output "MDE test simulation"'))
        Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -WindowStyle Hidden -EncodedCommand $encoded" -WindowStyle Hidden -ErrorAction Stop | Out-Null
        Add-Result 'EDR Simulation' 'Executed' 'Benign encoded PowerShell executed. Validate device timeline and alerts in Defender portal.'
    }
    catch {
        Add-Result 'EDR Simulation' 'Failed' $_.Exception.Message
    }
}

function Test-GraphModule {
    try {
        $mod = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication | Select-Object -First 1
        if ($mod) {
            Add-Result 'Graph Module' 'Passed' "Microsoft.Graph available. Version: $($mod.Version)"
        }
        else {
            Add-Result 'Graph Module' 'Warning' 'Microsoft.Graph PowerShell module not installed.'
        }
    }
    catch {
        Add-Result 'Graph Module' 'Warning' $_.Exception.Message
    }
}

function Test-GraphConnection {
    try {
        $ctx = Get-MgContext -ErrorAction Stop
        if ($ctx -and $ctx.Account) {
            Add-Result 'Graph Connection' 'Passed' "Connected as $($ctx.Account)"
        }
        else {
            Add-Result 'Graph Connection' 'Warning' 'Graph module present, but no active connection found.'
        }
    }
    catch {
        Add-Result 'Graph Connection' 'Warning' 'No active Graph connection found.'
    }
}

function Get-MDEAlerts {
    try {
        $ctx = Get-MgContext -ErrorAction Stop
        if (-not $ctx -or -not $ctx.Account) {
            Add-Result 'Alert Retrieval' 'Warning' 'Skipped because no Graph connection is active.'
            return
        }

        $uri = 'https://graph.microsoft.com/v1.0/security/alerts?$top=5'
        $alerts = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop

        if ($alerts.value -and $alerts.value.Count -gt 0) {
            $sampleTitles = @()

            foreach ($alert in ($alerts.value | Select-Object -First 3)) {
                if ($alert -is [System.Collections.IDictionary]) {
                    if ($alert.Contains('title') -and $alert['title']) {
                        $sampleTitles += [string]$alert['title']
                    }
                    elseif ($alert.Contains('Title') -and $alert['Title']) {
                        $sampleTitles += [string]$alert['Title']
                    }
                    elseif ($alert.Contains('id') -and $alert['id']) {
                        $sampleTitles += "Alert ID: $($alert['id'])"
                    }
                    else {
                        $sampleTitles += 'Alert returned without title field'
                    }
                }
                else {
                    if ($alert.PSObject.Properties['title'] -and $alert.title) {
                        $sampleTitles += [string]$alert.title
                    }
                    elseif ($alert.PSObject.Properties['Title'] -and $alert.Title) {
                        $sampleTitles += [string]$alert.Title
                    }
                    elseif ($alert.PSObject.Properties['id'] -and $alert.id) {
                        $sampleTitles += "Alert ID: $($alert.id)"
                    }
                    else {
                        $sampleTitles += 'Alert returned without title field'
                    }
                }
            }

            $sample = $sampleTitles -join '; '
            Add-Result 'Alert Retrieval' 'Passed' "Retrieved $($alerts.value.Count) alert(s). Sample: $sample"
        }
        else {
            Add-Result 'Alert Retrieval' 'Warning' 'Query succeeded but returned no alerts.'
        }
    }
    catch {
        Add-Result 'Alert Retrieval' 'Warning' $_.Exception.Message
    }
}

function Export-ResultsJson {
    Initialize-MDEFramework
    $jsonPath = Join-Path $script:LogDir 'results.json'
    $script:Results | ConvertTo-Json -Depth 4 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Log -Message "Results exported to $jsonPath" -Level INFO
    return $jsonPath
}

function Export-ResultsHtml {
    Initialize-MDEFramework
    $htmlPath = Join-Path $script:LogDir 'results.html'

    $rows = foreach ($r in $script:Results) {
        $statusClass = switch ($r.Status) {
            'Passed'   { 'passed' }
            'Warning'  { 'warning' }
            'Failed'   { 'failed' }
            'Executed' { 'executed' }
            default    { 'default' }
        }

@"
<tr class="$statusClass">
    <td>$($r.TestName)</td>
    <td>$($r.Status)</td>
    <td>$($r.Details)</td>
    <td>$(Get-Date $r.Time -Format 'yyyy-MM-dd HH:mm:ss')</td>
</tr>
"@
    }

    $summary = $script:Results | Group-Object Status | Sort-Object Name | ForEach-Object {
        "<li><strong>$($_.Name):</strong> $($_.Count)</li>"
    }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>MDE Test Framework Results</title>
    <style>
        body {
            font-family: Segoe UI, Arial, sans-serif;
            margin: 24px;
            background: #f7f7f7;
            color: #222;
        }
        h1 {
            margin-bottom: 8px;
        }
        .meta, .summary {
            background: #fff;
            border: 1px solid #ddd;
            padding: 16px;
            margin-bottom: 20px;
            border-radius: 8px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            background: #fff;
            border: 1px solid #ddd;
        }
        th, td {
            text-align: left;
            padding: 10px;
            border-bottom: 1px solid #e5e5e5;
            vertical-align: top;
        }
        th {
            background: #311640;
            color: white;
        }
        tr.passed td {
            background: #edf9ed;
        }
        tr.warning td {
            background: #fff8e5;
        }
        tr.failed td {
            background: #fdecec;
        }
        tr.executed td {
            background: #eef4ff;
        }
        tr.default td {
            background: #ffffff;
        }
        ul {
            margin: 0;
            padding-left: 20px;
        }
        .footer {
            margin-top: 18px;
            font-size: 12px;
            color: #666;
        }
    </style>
</head>
<body>
    <h1>MDE Test Framework Results</h1>

    <div class="meta">
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Host:</strong> $env:COMPUTERNAME</p>
        <p><strong>User:</strong> $env:USERNAME</p>
    </div>

    <div class="summary">
        <h2>Summary</h2>
        <ul>
            $($summary -join "`n")
        </ul>
    </div>

    <table>
        <thead>
            <tr>
                <th>Test Name</th>
                <th>Status</th>
                <th>Details</th>
                <th>Time</th>
            </tr>
        </thead>
        <tbody>
            $($rows -join "`n")
        </tbody>
    </table>

    <div class="footer">
        Generated by MDE Test Framework
    </div>
</body>
</html>
"@

    Set-Content -Path $htmlPath -Value $html -Encoding UTF8
    Write-Log -Message "HTML report exported to $htmlPath" -Level INFO
    return $htmlPath
}

function Invoke-MDETests {
    param(
        [switch]$SkipEICAR,
        [switch]$SkipGraph
    )

    Initialize-MDEFramework
    $script:Results = @()

    Write-Log -Message 'Starting test run.' -Level INFO

    Test-DefenderService
    Test-AVStatus
    Test-ASR

    if (-not $SkipEICAR) {
        Test-EICAR
    }

    Test-EDR
    Test-GraphModule

    if (-not $SkipGraph) {
        Test-GraphConnection
        Get-MDEAlerts
    }

    $jsonPath = Export-ResultsJson
    Add-Result 'Results Export (JSON)' 'Passed' "Results written to $jsonPath"

    $htmlPath = Export-ResultsHtml
    Add-Result 'Results Export (HTML)' 'Passed' "Results written to $htmlPath"

    return $script:Results
}

Export-ModuleMember -Function Initialize-MDEFramework,Write-Log,Invoke-MDETests,Export-ResultsJson,Export-ResultsHtml