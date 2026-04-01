Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Import-Module .\MDETestFramework.psm1 -Force

$form = New-Object System.Windows.Forms.Form
$form.Text = "MDE Test Framework v2"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(900, 620)
$form.MinimumSize = New-Object System.Drawing.Size(900, 620)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Tests"
$btnRun.Location = New-Object System.Drawing.Point(20, 20)
$btnRun.Size = New-Object System.Drawing.Size(130, 35)

$btnGraph = New-Object System.Windows.Forms.Button
$btnGraph.Text = "Connect Graph"
$btnGraph.Location = New-Object System.Drawing.Point(165, 20)
$btnGraph.Size = New-Object System.Drawing.Size(130, 35)

$btnLogs = New-Object System.Windows.Forms.Button
$btnLogs.Text = "Open Logs Folder"
$btnLogs.Location = New-Object System.Drawing.Point(310, 20)
$btnLogs.Size = New-Object System.Drawing.Size(140, 35)

$chkEicar = New-Object System.Windows.Forms.CheckBox
$chkEicar.Text = "Run EICAR test"
$chkEicar.Location = New-Object System.Drawing.Point(470, 27)
$chkEicar.AutoSize = $true
$chkEicar.Checked = $true

$chkGraph = New-Object System.Windows.Forms.CheckBox
$chkGraph.Text = "Run Graph checks"
$chkGraph.Location = New-Object System.Drawing.Point(610, 27)
$chkGraph.AutoSize = $true
$chkGraph.Checked = $true

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready."
$lblStatus.Location = New-Object System.Drawing.Point(20, 65)
$lblStatus.Size = New-Object System.Drawing.Size(820, 20)

$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(20, 95)
$listView.Size = New-Object System.Drawing.Size(840, 380)
$listView.View = 'Details'
$listView.FullRowSelect = $true
$listView.GridLines = $true

[void]$listView.Columns.Add("Test Name", 170)
[void]$listView.Columns.Add("Status", 100)
[void]$listView.Columns.Add("Details", 430)
[void]$listView.Columns.Add("Time", 140)

$txtSummary = New-Object System.Windows.Forms.TextBox
$txtSummary.Location = New-Object System.Drawing.Point(20, 490)
$txtSummary.Size = New-Object System.Drawing.Size(840, 70)
$txtSummary.Multiline = $true
$txtSummary.ScrollBars = "Vertical"
$txtSummary.ReadOnly = $true

function Add-ListRow {
    param($Result)

    $item = New-Object System.Windows.Forms.ListViewItem($Result.TestName)
    [void]$item.SubItems.Add([string]$Result.Status)
    [void]$item.SubItems.Add([string]$Result.Details)
    [void]$item.SubItems.Add((Get-Date $Result.Time -Format 'yyyy-MM-dd HH:mm:ss'))
    [void]$listView.Items.Add($item)
}

$btnGraph.Add_Click({
    try {
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Microsoft Graph PowerShell is not installed.`r`nRun: Install-Module Microsoft.Graph -Scope CurrentUser",
                "Module Missing"
            ) | Out-Null
            return
        }

        Connect-MgGraph -Scopes "SecurityEvents.Read.All","Directory.Read.All","AuditLog.Read.All"
        $ctx = Get-MgContext
        $lblStatus.Text = "Connected to Microsoft Graph as $($ctx.Account)"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Graph Connection Error") | Out-Null
    }
})

$btnLogs.Add_Click({
    $logPath = Join-Path $PSScriptRoot 'logs'
    if (-not (Test-Path -LiteralPath $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }
    Start-Process explorer.exe $logPath
})

$btnRun.Add_Click({
    try {
        $btnRun.Enabled = $false
        $listView.Items.Clear()
        $txtSummary.Clear()
        $lblStatus.Text = "Running tests..."

        $results = Invoke-MDETests -SkipEICAR:(!$chkEicar.Checked) -SkipGraph:(!$chkGraph.Checked)

        foreach ($r in $results) {
            Add-ListRow -Result $r
        }

        $summary = $results | Group-Object Status | Sort-Object Name | ForEach-Object {
            "{0}: {1}" -f $_.Name, $_.Count
        }

        $txtSummary.Text = ($summary -join [Environment]::NewLine)
        $lblStatus.Text = "Run complete."
    }
    catch {
        $lblStatus.Text = "Run failed."
        [System.Windows.Forms.MessageBox]::Show($_.Exception.ToString(), "Execution Error") | Out-Null
    }
    finally {
        $btnRun.Enabled = $true
    }
})

$form.Controls.AddRange(@(
    $btnRun,
    $btnGraph,
    $btnLogs,
    $chkEicar,
    $chkGraph,
    $lblStatus,
    $listView,
    $txtSummary
))

[void]$form.ShowDialog()