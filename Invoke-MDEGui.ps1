Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Import-Module .\MDETestFramework.psm1 -Force

$form = New-Object System.Windows.Forms.Form
$form.Text = "MDE Test Framework"
$form.Size = New-Object System.Drawing.Size(700,500)

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "Run Tests"
$btn.Location = New-Object System.Drawing.Point(20,20)
$btn.Size = New-Object System.Drawing.Size(120,40)

$output = New-Object System.Windows.Forms.TextBox
$output.Multiline = $true
$output.ScrollBars = "Vertical"
$output.Size = New-Object System.Drawing.Size(640,350)
$output.Location = New-Object System.Drawing.Point(20,80)

$btn.Add_Click({
    $output.Clear()
    $results = Invoke-MDETests

    foreach ($r in $results) {
        $output.AppendText("$($r.TestName) - $($r.Status)`r`n")
    }
})

$form.Controls.Add($btn)
$form.Controls.Add($output)

$form.ShowDialog()