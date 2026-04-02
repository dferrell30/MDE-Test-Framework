# 🛡️ MDE Test Framework

A PowerShell-based GUI tool for validating and testing Microsoft Defender for Endpoint (MDE) configurations and security controls.

---

## 🧠 Why This Exists

🛡️ **“Defender is deployed… we’re good.”**

Are you though?

In many environments:

- Policies look correct  
- Dashboards are green  
- Coverage appears complete  

But when tested:

- EICAR may not be blocked  
- ASR rules may not enforce  
- Detection visibility may be inconsistent  

👉 The reality:

**Security controls often fail silently.**

This framework was built to answer a simple but critical question:

> **“Is Microsoft Defender actually working as expected?”**

---

## 🚨 Problem Statement

Many environments rely on Microsoft Defender for Endpoint and assume protection is working because:

- Policies are configured  
- Devices are onboarded  
- Dashboards show healthy status  

However:

- Configuration does not guarantee enforcement  
- Security controls can fail silently  
- Detection visibility may not reflect real-world behavior  

👉 The gap:

There is no simple, repeatable way to **validate that Defender controls are actively protecting the endpoint**

This framework addresses that gap by enabling **safe, controlled testing of Defender capabilities**

---

## 🚀 How to Use

### Step 1 — Launch the Tool

```powershell
powershell -ExecutionPolicy Bypass -File .\Invoke-MDEGui.ps1

## 🎯 What Problem This Solves

Most organizations validate Defender by:

- Reviewing configuration settings  
- Checking compliance dashboards  
- Assuming policy = enforcement  

👉 But configuration ≠ protection

This tool helps you:

- Validate **actual enforcement**, not just settings  
- Simulate **real detection scenarios safely**  
- Identify gaps in:
  - Antivirus protection  
  - ASR rule enforcement  
  - EDR visibility and telemetry  

---

## 🕒 When to Use This

Use this framework when:

- ✔ After onboarding a device to Defender  
- ✔ After deploying or modifying policies (Intune / GPO)  
- ✔ During security validation or audits  
- ✔ When troubleshooting detection gaps  
- ✔ In lab or controlled production validation scenarios  

---

## ✅ Expected Outcomes

After running this tool, you should be able to:

- Confirm Defender sensor and AV health  
- Validate that ASR rules are actually enforced  
- Verify malware simulation is detected (EICAR)  
- Observe EDR telemetry generation  
- Produce:
  - JSON output (automation-ready)  
  - HTML report (human-readable)  
  - Execution logs  

---

---

## 📖 Full Documentation

➡️ [Security Playbook](./docs/PLAYBOOK.md)

---

## ⚠️ Disclaimer

This tool is provided for **educational, testing, and security validation purposes only**.

Use of this tool should be limited to:
- Authorized environments  
- Lab or approved enterprise systems  

The author assumes **no liability or responsibility** for:
- Misuse of this tool  
- Damage to systems  
- Unauthorized or improper use  

By using this tool, you agree to use it in a lawful and responsible manner.

---

This project is not affiliated with or endorsed by Microsoft.

---

## 🚀 Quick Start

```powershell
powershell -ExecutionPolicy Bypass -File .\Invoke-MDEGui.ps1
