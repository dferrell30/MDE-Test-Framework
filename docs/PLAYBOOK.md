# 🛡️ MDE Test Framework — Security Playbook

## 📌 Overview

This playbook provides operational guidance for validating Microsoft Defender for Endpoint.

---

## 🎯 Use Cases

- Security validation  
- Detection testing  
- SOC readiness  
- Deployment verification  

---

## 🧪 Test Methodology

1. Execute test  
2. Capture result  
3. Log output  
4. Validate in Defender  

---

## 🚀 Execution

```powershell
powershell -ExecutionPolicy Bypass -File .\Invoke-MDEGui.ps1
```

---

## 🔎 Validation

Check in:

https://security.microsoft.com

---

## 📊 Outputs

- JSON  
- HTML  
- Logs  

---

## 🔐 Security Notes

- EICAR is safe  
- PowerShell simulation is benign  
- Use least privilege for Graph  

---

## 🛠️ Troubleshooting

- Ensure Defender is enabled  
- Ensure Graph module installed  

