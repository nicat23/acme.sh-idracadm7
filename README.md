# 🛡️ ACME.sh with Dell iDRAC Support — Containerized Edition

This container integrates [acme.sh](https://github.com/acmesh-official/acme.sh) with Dell iDRAC via `racadm`, enabling automated certificate issuance and deployment for enterprise-grade server environments.

---

## 🚀 Features

- ✅ Full acme.sh support for Let's Encrypt and other ACME CAs  
- 🔐 Dell iDRAC integration via `racadm`  
- 🔄 Automatic certificate renewal via cron  
- 🧩 Custom deploy hooks, DNS APIs, and notification scripts  
- 🧪 Dry-run and debug toggles for safe experimentation  
- 🐳 Alpine-based image with minimal footprint  
- 🔒 Runs as non-root by default (UID/GID 1000)

---

## 📦 Container Architecture

