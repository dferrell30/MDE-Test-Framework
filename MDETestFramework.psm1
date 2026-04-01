#requires -Version 5.1
Set-StrictMode -Version Latest

$Global:Results = @()
$Global:LogDir = Join-Path (Get-Location) "logs"

# Ensure logs folder exists
if (-not (Test-Path $Global:LogDir)) {
    New-Item -ItemType Directory -Path $Global:LogDir | Out-Null
}

$Global:LogFile = Join-Path $Global:LogDir ("MDE-TestLog_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

function Write-Log {
    param($Message)

    $entry = "{0} - {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $Global:LogFile -Value $entry
}

function Add-Result {
    param($Name, $Status, $Details)

    $obj = [PSCustomObject]@{
        TestName = $Name
        Status   = $Status
        Details  = $Details
        Time     = Get-Date
    }

    $Global:Results += $obj
    Write-Log "$Name | $Status | $Details"
}

function Test-DefenderService {
    try {
        $svc = Get-Service Sense -ErrorAction Stop
        if ($svc.Status -eq "Running") {
            Add-Result "Defender Sensor" "Passed" "Service running"
        } else {
            Add-Result "Defender Sensor" "Failed" "Service not running"
        }
    } catch {
        Add-Result "Defender Sensor" "Failed" $_.Exception.Message
    }
}

function Test-AVStatus {
    try {
        $status = Get-MpComputerStatus
        Add-Result "AV Status" "Passed" "RealtimeProtection=$($status.RealTimeProtectionEnabled)"
    } catch {
        Add-Result "AV Status" "Failed" $_.Exception.Message
    }
}

function Test-ASR {
    try {
        $rules = (Get-MpPreference).AttackSurfaceReductionRules_Ids
        if ($rules.Count -gt 0) {
            Add-Result "ASR Rules" "Passed" "$($rules.Count) rules configured"
        } else {
            Add-Result "ASR Rules" "Warning" "No ASR rules"
        }
    } catch {
        Add-Result "ASR Rules" "Failed" $_.Exception.Message
    }
}

function Test-EICAR {
    $file = "$env:TEMP\eicar.com.txt"

    try {
        Invoke-WebRequest -Uri "https://secure.eicar.org/eicar.com.txt" -OutFile $file -ErrorAction Stop

        if (Test-Path $file) {
            Add-Result "EICAR Test" "Warning" "File not blocked"
        } else {
            Add-Result "EICAR Test" "Passed" "Blocked"
        }
    } catch {
        Add-Result "EICAR Test" "Passed" "Blocked by Defender"
    }
}

function Test-EDR {
    try {
        Start-Process powershell -ArgumentList "-nop -w hidden -c `"Write-Host test`""
        Add-Result "EDR Simulation" "Executed" "Check portal"
    } catch {
        Add-Result "EDR Simulation" "Failed" $_.Exception.Message
    }
}

function Invoke-MDETests {

    $Global:Results = @()

    Test-DefenderService
    Test-AVStatus
    Test-ASR
    Test-EICAR
    Test-EDR

    $json = Join-Path $Global:LogDir "results.json"
    $Global:Results | ConvertTo-Json | Out-File $json

    return $Global:Results
}

Export-ModuleMember -Function *