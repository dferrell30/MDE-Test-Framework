# 📄 Changelog

All notable changes to this project will be documented in this file.

This project follows a structured release format and semantic-style versioning.

---

## [v1.0] - Release 0.1 - Initial Release

### ✨ Added

- Initial release of the MDE Test Framework
- GUI-based PowerShell test runner
- Core module (`MDETestFramework.psm1`)
- Logging framework with timestamped output
- JSON result export (`results.json`)
- HTML report export (`results.html`)
- Logs directory auto-creation

---

### 🛡️ Security Validation Features

- Defender sensor health check (`Sense` service)
- Antivirus status validation
- Attack Surface Reduction (ASR) rule detection
- EICAR malware simulation test
- EDR simulation using encoded PowerShell execution

---

### 🔗 Microsoft Graph Integration (Optional)

- Graph module detection
- Interactive authentication via `Connect-MgGraph`
- Alert retrieval from `/security/alerts`
- Validation of Defender telemetry ingestion

---

### 🖥️ GUI Enhancements

- Run Tests button
- Connect / Disconnect Graph
- Open Logs button
- Open HTML Report button
- EICAR test toggle
- ASR validation toggle
- Results table with status breakdown
- Summary output panel

---

### 📊 Reporting

- Structured JSON output for automation
- Styled HTML report with:
  - Status highlighting (Passed / Warning / Failed)
  - Summary section
  - Execution metadata
- Persistent log file per run

---

### 📘 Documentation

- README.md (quick start + overview)
- Security Playbook (`docs/PLAYBOOK.md`)
- Installation and execution guidance
- PowerShell setup instructions
- Graph permission requirements

---

### 🔐 Security & Governance

- MIT License added
- SECURITY.md policy added
- `.gitignore` configured to exclude logs and output files
- No hardcoded credentials or secrets
- Interactive authentication model (secure by design)

---

### ⚠️ Notes

- Designed for Defender validation and testing
- Safe for lab and controlled enterprise environments
- Not intended for offensive or malicious use

---

## 🔮 Future Enhancements

- HTML report improvements (branding / theming)
- Device posture reporting
- KQL validation integration
- Scheduled execution support
- CI/CD integration
- Signed PowerShell modules
- Expanded Defender coverage

- ## [v1.1] - Release 0.2

### ✨ Added
- New feature...

### 🔧 Changed
- Updated...

### 🐛 Fixed
- Bug fix...

---
