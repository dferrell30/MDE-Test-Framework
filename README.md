# 🛡️ Microsoft Defender for Endpoint Validation Framework

![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-5391FE?style=flat&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Platform-Windows-0078D6?style=flat&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

---

## 🛡️ The Problem

Defender can show as fully healthy.

That does not mean it’s working.

This framework helps you prove it.

## ✅ What This Framework Does

This framework allows you to safely simulate activity and validate how Defender actually behaves on an endpoint. Designed to be simple to run with minimal setup.

---

## ⚠️ If Results Don’t Match Expectations

Results may vary depending on:

- Defender mode (active vs passive)
- Onboarding state
- Licensing level
- Telemetry delays

Always validate device configuration before assuming failure.

## 🛡️ The Problem

Defender can appear fully onboarded and healthy.

But that does not guarantee detection and response are working as expected.

This framework helps validate that behavior in a controlled, safe way.

---

## 🎯 Who This Framework Is For

- Security engineers validating Defender deployments
- Administrators onboarding Microsoft Defender for Endpoint
- Teams testing security controls in lab or production environments

---

## 📑 Table of Contents

- OverviewWhat
- This Framework Validates
- Architecture
- Features
- Quick Start
- Test Categories
- Expected Outcomes & Verification
- Reporting
- Repository Structure
- Roadmap
- Requirements
- Disclaimers

# 📘 Overview

Deploying Microsoft Defender for Endpoint is only part of the solution.

This framework helps answer a more important question:

Are your endpoint security controls actually working as expected?

This project provides a structured approach to validating:

- Endpoint protection readiness
- Prevention controls (AV / ASR)
- Detection and telemetry generation
- Alert visibility through Microsoft Graph
- Analyst verification workflows

# 🎯 What This Framework Validates

This is not a vulnerability scanner or offensive tool.

It is a defensive validation framework designed to safely test:

✔️ Defender AV detection capability (EICAR)
✔️ Endpoint Detection & Response (EDR) telemetry
✔️ Attack Surface Reduction (ASR) configuration
✔️ Microsoft Graph alert visibility
✔️ Endpoint sensor and platform health
🏗️ Architecture

The framework is organized into validation domains:

- Platform Health
- Defender sensor (Sense service)
- AV status and readiness
- Prevention Validation
- Antivirus detection testing
- ASR configuration checks
- Detection & Telemetry
- Benign EDR simulation (encoded PowerShell)
- Timeline artifact generation
- Cloud Visibility
- Microsoft Graph connectivity
- Alert retrieval and inspection
- Reporting
- JSON output for automation
- HTML report for analysis and demonstration
  
# ⚙️ Features

- GUI-based execution (Invoke-MDEGui.ps1)
- Modular PowerShell framework (MDETestFramework.psm1)
- Safe AV validation using EICAR test string
- Benign EDR simulation for telemetry validation
- Microsoft Graph integration for alert retrieval
- JSON + HTML reporting outputs
- Designed for lab and enterprise validation scenarios

---

## 📸 Example Output

### GUI

![GUI Overview](./images/gui-overview.png)
![GUI Run](./images/gui-run.png)

### Validation Report

![Report Summary](./images/report-summary.png)
![Report Details](./images/report-details.png)

---
  
## 🚀 Quick Start

⚠️ Run PowerShell as Administrator for best results.

1. Clone the repository:

```powershell
git clone https://github.com/dferrell30/MDE-Test-Framework.git
cd MDE-Test-Framework
```
#Bypass if needed

 ```Powershell
 Set-ExecutionPolicy Bypass -Scope CurrentUser
```

#Powershell once at root

```PowerShell
.\Invoke-MDEGui.ps1
```

---

2. Run validation tests
- Select desired test options
- Connect to Microsoft Graph (optional)
- Execute tests
- Review results in HTML or JSON output
  
## 🧪 Test Categories

> 🧪 Tested in a lab environment. Results may vary based on Defender configuration, onboarding state, and licensing.

- Platform Health
- Validates Defender sensor and service status
- Confirms AV readiness and configuration
- Prevention Validation
- Executes EICAR test for AV detection validation
- Verifies ASR rule configuration presence
- Detection & Telemetry
- Executes benign encoded PowerShell
- Generates telemetry for timeline and hunting validation\
- Cloud Visibility
- Tests Microsoft Graph connectivity
- Retrieves recent Defender alerts

---

## 🔍 Expected Outcomes

| Test | Expected Result | Where to Validate | Why It Matters |
|------|---------------|------------------|----------------|
| EICAR Test | File detected or quarantined | Device timeline / alerts | Confirms AV detection is working |
| PowerShell Simulation | Process execution logged | Device timeline | Validates EDR telemetry visibility |
| Alert Retrieval | Alerts returned via Graph | MDE Portal / API | Ensures alerts are generated and accessible |
| ASR Checks | Rules enforced or reported | Defender settings / logs | Verifies attack surface reduction coverage |

Note: Some detections depend on policy configuration, sensitivity levels, and environment tuning.

---

📊 Reporting

The framework generates:

- JSON Output
- Structured results for automation
- Suitable for pipelines or further analysis
- HTML Report
- Human-readable validation report
- Useful for demos, audits, and validation evidence

## Example Output of HTML File

![Report Summary](./images/report-summary.png)
![Report Details](./images/report-details.png)

# 📁 Repository Structure
MDE-Test-Framework/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── .gitignore
├── SECURITY.md
├── Invoke-MDEGui.ps1
├── MDETestFramework.psm1
├── docs/
│   └── PLAYBOOK.md
└── logs/
    └── .gitkeep

# 🛣️ Roadmap
 
 - ASR behavioral validation tests
 - Expected vs actual result mapping
 - Enhanced HTML reporting (analyst guidance)
 - Alert-to-test correlation
 - Advanced Hunting (KQL) integration
 - Expanded validation scenarios

# 🧰 Requirements

- Windows endpoint with Microsoft Defender for Endpoint onboarded
- PowerShell 5.1+ or PowerShell 7+
- Microsoft Graph PowerShell SDK (for cloud validation)
- Appropriate permissions for Graph queries
  
# ⚠️ Disclaimers

This project is intended for defensive security validation and educational use.

Do not use this framework in unauthorized environments
Do not use for offensive or malicious purposes
Always perform testing in approved lab or enterprise environments
Some tests generate telemetry that may trigger alerts

The author is not responsible for misuse of this tool or unintended impacts resulting from its execution.
