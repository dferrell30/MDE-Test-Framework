# 📦 How to Install PowerShell
Option 1: Use Windows PowerShell 5.1

Most Windows systems already include Windows PowerShell 5.1.

---

## How to open it
Click Start
Type PowerShell
Click Windows PowerShell

For best results:

Right-click Windows PowerShell
Choose Run as administrator
How to confirm version

Run:

$PSVersionTable.PSVersion

If you see 5.1.x, no additional installation is required.

Option 2: Install PowerShell 7

PowerShell 7 is optional, but supported.

Install with Winget

Run in Command Prompt or PowerShell:

winget install --id Microsoft.PowerShell --source winget
After installation

Open PowerShell 7 by searching for:

PowerShell 7

Then verify:

$PSVersionTable.PSVersion
📁 Repository Setup

After downloading or cloning the repository, your folder should look like this:

MDE-Test-Framework/
├── Invoke-MDEGui.ps1
├── MDETestFramework.psm1
├── README.md
├── docs/
│   └── PLAYBOOK.md
└── logs/

The logs folder can be empty. The framework will create output files automatically.

🔐 Permissions
Local permissions
Permission	Needed
Run PowerShell scripts	Yes
Read Defender status	Yes
Local Administrator	Recommended
Optional Microsoft Graph permissions

If using Graph validation, connect with delegated permissions such as:

SecurityEvents.Read.All
Directory.Read.All
AuditLog.Read.All

An app registration is not required for manual interactive use.

🚀 How to Run the Application
Step 1: Open PowerShell

Open either:

Windows PowerShell 5.1
PowerShell 7

Run as Administrator if possible.

Step 2: Change to the project folder

Example:

cd "C:\Users\<YourUser>\Desktop\MDE-Test-Framework"

Use quotes if the path contains spaces.

Step 3: If needed, allow this session to run scripts
Option A — Recommended one-time launch

Run the script directly with Bypass:

powershell -ExecutionPolicy Bypass -File .\Invoke-MDEGui.ps1

This is the simplest method.

Option B — Set policy for current session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Then run:

.\Invoke-MDEGui.ps1
Step 4: If files were downloaded and blocked, unblock them

Run:

Unblock-File .\Invoke-MDEGui.ps1
Unblock-File .\MDETestFramework.psm1

Then run the application:

.\Invoke-MDEGui.ps1
Step 5: Use the GUI

Once the window opens:

Click Connect Graph if you want cloud alert validation
Select or clear:
Run EICAR Test
Run ASR Check
Click Run Tests
Review results in the grid
Open logs or HTML report as needed
🔗 Microsoft Graph Connection

Graph connection is optional.

Install Microsoft Graph PowerShell module
Install-Module Microsoft.Graph -Scope CurrentUser
Connect manually if needed
Connect-MgGraph -Scopes "SecurityEvents.Read.All","Directory.Read.All","AuditLog.Read.All"
Disconnect
Disconnect-MgGraph
🧪 Test Scenarios
Defender Sensor

Checks whether the Sense service is running.

AV Status

Checks whether Defender Antivirus and real-time protection are enabled.

ASR Rules

Checks whether Attack Surface Reduction rules are configured.

EICAR Test

Downloads the standard EICAR test file to confirm Defender detection behavior.

EDR Simulation

Launches a benign encoded PowerShell process to create telemetry for validation.

Graph Module / Graph Connection / Alert Retrieval

Confirms Graph module availability, sign-in status, and alert query capability.

📊 Output and Reports

All outputs are written to:

.\logs\
Files generated
File	Purpose
MDE-TestLog_YYYYMMDD_HHMMSS.log	Execution log
results.json	Structured machine-readable results
results.html	Human-readable HTML report
Open logs folder
explorer .\logs
Open HTML report
start .\logs\results.html
🛠️ Troubleshooting
PowerShell says script cannot run

Use:

powershell -ExecutionPolicy Bypass -File .\Invoke-MDEGui.ps1

Or:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
PowerShell says file is blocked

Run:

Unblock-File .\Invoke-MDEGui.ps1
Unblock-File .\MDETestFramework.psm1
Graph sign-in window does not appear

It may open behind other windows.

Try:

minimizing the main app window
using Alt+Tab
clicking the Graph sign-in window from the taskbar
EICAR test shows warning

Possible reasons:

Defender exclusions
delayed remediation
network/web filtering differences

Check:

Get-MpThreatDetection

And verify in the Defender portal.

ASR check shows warning

This usually means no ASR rules are configured on the device.

That can be normal in a lab environment.

📂 Project Structure
MDE-Test-Framework/
├── Invoke-MDEGui.ps1
├── MDETestFramework.psm1
├── README.md
├── docs/
│   └── PLAYBOOK.md
├── logs/
│   ├── results.json
│   ├── results.html
│   └── MDE-TestLog_*.log
└── .gitignore
✅ Quick Launch Summary

If you only need the fastest path:

cd "C:\Path\To\MDE-Test-Framework"
powershell -ExecutionPolicy Bypass -File .\Invoke-MDEGui.ps1

If needed:

Unblock-File .\Invoke-MDEGui.ps1
Unblock-File .\MDETestFramework.psm1

For the **README**, keep it shorter and link to this playbook. The README should be the landing page; the playbook should be the full operating guide.

If you want, I can also generate a matching **clean README.md** that links to this exact playbook and uses the same GitHub-ready style.
