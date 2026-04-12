#requires -Version 5.1
Set-StrictMode -Version Latest

$script:Results = @()
$script:BasePath = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$script:LogDir = Join-Path $script:BasePath 'logs'
$script:LogFile = $null

$script:TestMetadata = @{
    'Defender Sensor' = @{
        Category          = 'Platform Health'
        ExpectedBehavior  = 'Microsoft Defender for Endpoint sensor service should be running.'
        ExpectedTelemetry = 'Endpoint sensor state available locally.'
        AlertExpectation  = 'No alert expected.'
        Verify            = 'Local service status / Defender portal device health'
    }
    'AV Status' = @{
        Category          = 'Platform Health'
        ExpectedBehavior  = 'Realtime protection and antivirus should be enabled.'
        ExpectedTelemetry = 'Local Defender AV health state available.'
        AlertExpectation  = 'No alert expected.'
        Verify            = 'Get-MpComputerStatus / Defender portal'
    }
    'ASR Configuration' = @{
        Category          = 'Prevention Validation'
        ExpectedBehavior  = 'ASR rules should be present and configured.'
        ExpectedTelemetry = 'Configuration visible on endpoint.'
        AlertExpectation  = 'No alert expected (configuration validation only).'
        Verify            = 'Get-MpPreference / Intune / Defender portal'
    }
    'EICAR Test' = @{
        Category          = 'Prevention Validation'
        ExpectedBehavior  = 'EICAR test file should be blocked, quarantined, or removed by Defender AV.'
        ExpectedTelemetry = 'Malware detection event should be logged.'
        AlertExpectation  = 'Alert may be generated depending on policy and environment tuning.'
        Verify            = 'Defender portal device timeline / Incidents & alerts'
    }
    'EDR Simulation' = @{
        Category          = 'Detection & Telemetry'
        ExpectedBehavior  = 'Benign encoded PowerShell should execute successfully in most environments.'
        ExpectedTelemetry = 'Process creation and command-line activity should be visible.'
        AlertExpectation  = 'Environment dependent; may or may not generate an alert.'
        Verify            = 'Device timeline / Advanced Hunting'
    }
    'Graph Module' = @{
        Category          = 'Cloud Visibility'
        ExpectedBehavior  = 'Microsoft Graph PowerShell module should be installed for cloud validation.'
        ExpectedTelemetry = 'Local module availability can be confirmed.'
        AlertExpectation  = 'No alert expected.'
        Verify            = 'Get-Module -ListAvailable'
    }
    'Graph Connection' = @{
        Category          = 'Cloud Visibility'
        ExpectedBehavior  = 'An active Graph connection should be present when cloud validation is used.'
        ExpectedTelemetry = 'Graph context should show authenticated account details.'
        AlertExpectation  = 'No alert expected.'
        Verify            = 'Get-MgContext'
    }
    'Alert Retrieval' = @{
        Category          = 'Cloud Visibility'
        ExpectedBehavior  = 'Recent alerts should be retrievable through Microsoft Graph if accessible.'
        ExpectedTelemetry = 'Alert metadata should be returned from the Graph API.'
        AlertExpectation  = 'Existing alerts should be visible if present.'
        Verify            = 'Defender portal / Microsoft Graph API'
    }
}

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

function Get-TestMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($script:TestMetadata.ContainsKey($Name)) {
        return $script:TestMetadata[$Name]
    }

    return @{
        Category          = 'General'
        ExpectedBehavior  = 'Review test details.'
        ExpectedTelemetry = 'Review test details.'
        AlertExpectation  = 'Review test details.'
        Verify            = 'Review test details.'
    }
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

    $meta = Get-TestMetadata -Name $Name

    $item = [PSCustomObject]@{
        TestName          = $Name
        Category          = [string]$meta.Category
        Status            = $Status
        Details           = $Details
        ExpectedBehavior  = [string]$meta.ExpectedBehavior
        ExpectedTelemetry = [string]$meta.ExpectedTelemetry
        AlertExpectation  = [string]$meta.AlertExpectation
        Verify            = [string]$meta.Verify
        Time              = Get-Date
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

function ConvertTo-HtmlEncoded {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ''
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-CategorySummary {
    $categories = 'Platform Health', 'Prevention Validation', 'Detection & Telemetry', 'Cloud Visibility'

    foreach ($category in $categories) {
        $items = @($script:Results | Where-Object { $_.Category -eq $category })

        if ($items.Count -eq 0) {
            [PSCustomObject]@{
                Category = $category
                Result   = 'Not Run'
            }
            continue
        }

        if ($items.Status -contains 'Failed') {
            $result = 'Failed'
        }
        elseif ($items.Status -contains 'Warning') {
            $result = 'Needs Review'
        }
        elseif ($items.Status -contains 'Executed') {
            $result = 'Needs Review'
        }
        else {
            $result = 'Passed'
        }

        [PSCustomObject]@{
            Category = $category
            Result   = $result
        }
    }
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
            Add-Result 'ASR Configuration' 'Passed' "$($rules.Count) ASR rule(s) configured."
        }
        else {
            Add-Result 'ASR Configuration' 'Warning' 'No ASR rules configured on this endpoint.'
        }
    }
    catch {
        Add-Result 'ASR Configuration' 'Failed' $_.Exception.Message
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
        Add-Result 'EDR Simulation' 'Executed' 'Benign encoded PowerShell executed. Validate process execution, command-line visibility, and any related alerts in the Defender portal.'
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
    $script:Results | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Log -Message "Results exported to $jsonPath" -Level INFO
    return $jsonPath
}

function Export-ResultsHtml {
    Initialize-MDEFramework
    $htmlPath = Join-Path $script:LogDir 'results.html'

    $summary = $script:Results | Group-Object Status | Sort-Object Name | ForEach-Object {
        "<li><strong>$([System.Net.WebUtility]::HtmlEncode($_.Name)):</strong> $($_.Count)</li>"
    }

    $categorySummaryRows = foreach ($item in (Get-CategorySummary)) {
        $class = switch ($item.Result) {
            'Passed'      { 'passed' }
            'Failed'      { 'failed' }
            'Needs Review'{ 'warning' }
            default       { 'default' }
        }

        @"
<tr class="$class">
    <td>$(ConvertTo-HtmlEncoded $item.Category)</td>
    <td>$(ConvertTo-HtmlEncoded $item.Result)</td>
</tr>
"@
    }

    $categories = 'Platform Health', 'Prevention Validation', 'Detection & Telemetry', 'Cloud Visibility', 'General'

    $sections = foreach ($category in $categories) {
        $items = @($script:Results | Where-Object { $_.Category -eq $category })
        if ($items.Count -eq 0) {
            continue
        }

        $rows = foreach ($r in $items) {
            $statusClass = switch ($r.Status) {
                'Passed'   { 'passed' }
                'Warning'  { 'warning' }
                'Failed'   { 'failed' }
                'Executed' { 'executed' }
                default    { 'default' }
            }

@"
<tr class="$statusClass">
    <td>$(ConvertTo-HtmlEncoded $r.TestName)</td>
    <td>$(ConvertTo-HtmlEncoded $r.Status)</td>
    <td>$(ConvertTo-HtmlEncoded $r.Details)</td>
    <td>$(ConvertTo-HtmlEncoded $r.ExpectedBehavior)</td>
    <td>$(ConvertTo-HtmlEncoded $r.ExpectedTelemetry)</td>
    <td>$(ConvertTo-HtmlEncoded $r.AlertExpectation)</td>
    <td>$(ConvertTo-HtmlEncoded $r.Verify)</td>
    <td>$(Get-Date $r.Time -Format 'yyyy-MM-dd HH:mm:ss')</td>
</tr>
"@
        }

@"
<div class="section">
    <h2>$(ConvertTo-HtmlEncoded $category)</h2>
    <table>
        <thead>
            <tr>
                <th>Test Name</th>
                <th>Status</th>
                <th>Details</th>
                <th>Expected Behavior</th>
                <th>Expected Telemetry</th>
                <th>Alert Expectation</th>
                <th>Where to Verify</th>
                <th>Time</th>
            </tr>
        </thead>
        <tbody>
            $($rows -join "`n")
        </tbody>
    </table>
</div>
"@
    }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>MDE Validation Framework Results</title>
    <style>
        body {
            font-family: Segoe UI, Arial, sans-serif;
            margin: 24px;
            background: #f7f7f7;
            color: #222;
        }
        h1, h2 {
            margin-bottom: 8px;
        }
        h1 {
            color: #311640;
        }
        .meta, .summary, .executive {
            background: #fff;
            border: 1px solid #ddd;
            padding: 16px;
            margin-bottom: 20px;
            border-radius: 8px;
        }
        .section {
            margin-bottom: 28px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            background: #fff;
            border: 1px solid #ddd;
            table-layout: fixed;
        }
        th, td {
            text-align: left;
            padding: 10px;
            border-bottom: 1px solid #e5e5e5;
            vertical-align: top;
            word-wrap: break-word;
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
        .note {
            font-size: 13px;
            color: #444;
            margin-top: 8px;
        }
    </style>
</head>
<body>
    <h1>MDE Validation Framework Results</h1>

    <div class="meta">
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Host:</strong> $(ConvertTo-HtmlEncoded $env:COMPUTERNAME)</p>
        <p><strong>User:</strong> $(ConvertTo-HtmlEncoded $env:USERNAME)</p>
        <p><strong>Log File:</strong> $(ConvertTo-HtmlEncoded $script:LogFile)</p>
    </div>

    <div class="executive">
        <h2>Executive Summary</h2>
        <table>
            <thead>
                <tr>
                    <th>Validation Domain</th>
                    <th>Result</th>
                </tr>
            </thead>
            <tbody>
                $($categorySummaryRows -join "`n")
            </tbody>
        </table>
        <p class="note">Needs Review does not necessarily indicate failure. It typically reflects warnings, optional alert generation, or telemetry that should be confirmed by an analyst.</p>
    </div>

    <div class="summary">
        <h2>Status Summary</h2>
        <ul>
            $($summary -join "`n")
        </ul>
    </div>

    $($sections -join "`n")

    <div class="footer">
        Generated by MDE Validation Framework
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

    $null = Export-ResultsJson
    $null = Export-ResultsHtml

    return $script:Results
}

Export-ModuleMember -Function Initialize-MDEFramework,Write-Log,Invoke-MDETests,Export-ResultsJson,Export-ResultsHtml
