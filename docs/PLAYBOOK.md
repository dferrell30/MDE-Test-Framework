# 🛡️ Defender for Endpoint Validation Playbook

## 📘 Purpose

This playbook provides a structured approach to validating the effectiveness, visibility, and behavior of Microsoft Defender for Endpoint (MDE) controls using the MDE Validation Framework.

This is not a deployment or configuration guide.

> This playbook is designed to help security engineers answer:
> **“Are my endpoint security controls working as expected?”**

---

## 🧰 Prerequisites

Before running validation tests, ensure:

* Microsoft Defender for Endpoint is onboarded on the target device
* Real-time protection is enabled
* PowerShell 5.1+ or PowerShell 7+ is available
* Appropriate permissions exist for Microsoft Graph (if using cloud validation)
* Testing is performed in an approved lab or enterprise environment

---

## 🚀 Running the Framework

### Launch the GUI

```powershell
powershell -ExecutionPolicy Bypass -File .\Invoke-MDEGui.ps1
```

### Available Options

| Option        | Description                                           |
| ------------- | ----------------------------------------------------- |
| Run Tests     | Executes all selected validation tests                |
| Connect Graph | Authenticates to Microsoft Graph for alert validation |
| EICAR Test    | Enables antivirus detection validation                |
| Graph Checks  | Enables cloud alert retrieval and validation          |

---

## 🧪 Validation Scenarios

### 🛡️ Antivirus Validation (EICAR)

**Purpose**
Validates that Microsoft Defender Antivirus is actively detecting known malicious signatures.

**Action**
The framework writes the EICAR test string to disk.

**Expected Behavior**

* File is immediately blocked or quarantined

**Expected Telemetry**

* Malware detection event logged on the device

**Alert Expectation**

* Alert may be generated depending on policy and sensitivity

**Where to Verify**

* Defender portal → Device timeline
* Defender portal → Incidents & alerts

---

### 🧠 EDR Telemetry Validation

**Purpose**
Validates that endpoint activity is captured and visible for investigation.

**Action**
Executes a benign Base64-encoded PowerShell command.

**Expected Behavior**

* Command executes successfully (not typically blocked)

**Expected Telemetry**

* Process creation event recorded
* Command-line activity visible

**Alert Expectation**

* Alert may or may not trigger depending on environment configuration

**Where to Verify**

* Defender portal → Device timeline
* Advanced Hunting (process events)

---

### ⚙️ ASR Configuration Validation

**Purpose**
Validates that Attack Surface Reduction (ASR) rules are configured on the endpoint.

**Action**
Checks for presence of ASR rule configurations.

**Expected Behavior**

* ASR rules are present and configured (Block/Audit/Warn)

**Expected Telemetry**

* Configuration visible on the endpoint

**Alert Expectation**

* No alert expected (configuration validation only)

**Where to Verify**

* Endpoint configuration
* Microsoft Intune / Defender portal

---

### ☁️ Cloud Alert Validation (Graph)

**Purpose**
Validates visibility of security alerts through Microsoft Graph.

**Action**
Connects to Microsoft Graph and retrieves recent alerts.

**Expected Behavior**

* Successful authentication and data retrieval

**Expected Telemetry**

* Alert metadata returned from Graph API

**Alert Expectation**

* Existing alerts visible if present

**Where to Verify**

* Defender portal → Incidents & alerts
* Microsoft Graph API output

---

## 🔍 How to Verify Results

### Device Timeline

Use the Defender portal device timeline to confirm:

* Malware detection events (EICAR)
* Process execution (EDR simulation)
* Command-line activity
* Security events generated during testing

---

### Advanced Hunting

Use Advanced Hunting to validate telemetry.

Example queries:

```kql
DeviceProcessEvents
| where Timestamp > ago(30m)
| where ProcessCommandLine contains "powershell"
```

```kql
DeviceEvents
| where Timestamp > ago(30m)
| where ActionType contains "Antivirus"
```

---

### Alerts & Incidents

Check for:

* Malware detection alerts (EICAR)
* Suspicious activity alerts (environment dependent)
* Incident correlation

> Note: Not all tests are expected to generate alerts. Lack of alerts does not necessarily indicate failure.

---

## 📊 Common Outcomes & Interpretation

| Scenario                                        | Meaning                                      |
| ----------------------------------------------- | -------------------------------------------- |
| EICAR not detected                              | Defender AV may be disabled or misconfigured |
| EICAR detected but no alert                     | Normal depending on alert configuration      |
| EDR simulation visible in timeline but no alert | Expected behavior in many environments       |
| No telemetry for EDR test                       | Possible sensor or logging issue             |
| No Graph alerts returned                        | May indicate no recent alerts, not a failure |

---

## ⚠️ Important Notes

* This framework uses **safe and controlled simulations only**
* No malicious payloads are used
* Some actions may generate alerts depending on environment configuration
* Always validate results across multiple data sources (timeline, hunting, alerts)

---

## 🚧 Limitations

* ASR validation is currently configuration-based (behavioral testing planned)
* Alert generation depends on environment tuning and policies
* Graph results depend on available data and permissions

---

## 🛣️ Next Steps

Future improvements include:

* Behavioral ASR validation scenarios
* Expected vs actual result comparison
* Enhanced reporting with analyst guidance
* Alert-to-test correlation
* Expanded Advanced Hunting queries

---

## ⚠️ Disclaimer

This playbook is intended for defensive security validation and educational use.

* Do not use in unauthorized environments
* Do not perform testing outside approved lab or enterprise environments
* Do not attempt to simulate malicious activity beyond what is provided

The author assumes no responsibility for misuse or unintended impact.
