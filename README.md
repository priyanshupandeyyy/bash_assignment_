# 🩺 Service Health Monitor — Bash Assignment

A production-grade Bash script that monitors Linux services, detects failures, attempts auto-recovery, and logs everything to a structured log file.

---

## 📋 Assignment Overview

> You are a DevOps engineer at a startup. The team runs several microservices on a Linux server. The on-call rotation is exhausted from manually restarting services whenever they crash. This script automates service monitoring, recovery, and reporting.

---

## 📁 Repository Structure

```
bash_assignment_/
├── health_monitor.sh   # Main monitoring script
├── services.txt        # List of services to monitor
├── screenshot.png      # Output screenshot
└── README.md           # This file
```

---

## ⚙️ Features

| Feature | Description |
|--------|-------------|
| ✅ Service Monitoring | Reads services from `services.txt` and checks each one |
| ✅ Auto Recovery | Restarts stopped services automatically |
| ✅ Re-verification | Waits 5 seconds after restart and re-checks status |
| ✅ Structured Logging | Logs events with timestamp and severity to `/var/log/health_monitor.log` |
| ✅ Summary Table | Prints total checked, healthy, recovered, and failed counts |
| ✅ Error Handling | Gracefully handles missing or empty `services.txt` |
| ✅ Dry Run Mode | `--dry-run` flag simulates without making any changes |

---

## 🚀 Usage

### 1. Clone the repository
```bash
git clone https://github.com/priyanshupandeyyy/bash_assignment_.git
cd bash_assignment_
```

### 2. Add services to monitor
```bash
nano services.txt
```
Example `services.txt`:
```
ssh
cron
NetworkManager
```

### 3. Make the script executable
```bash
chmod +x health_monitor.sh
```

### 4. Run the script
```bash
# Normal run (requires sudo for systemctl + log file)
sudo ./health_monitor.sh

# Dry-run mode (safe, no actual restarts)
./health_monitor.sh --dry-run
```

---

## 📄 Log Format

Logs are written to `/var/log/health_monitor.log` in this format:

```
[2025-01-15T14:32:10+0530] [OK]    service=ssh      msg="Service is healthy (active)."
[2025-01-15T14:32:11+0530] [WARN]  service=nginx    msg="Service is inactive. Attempting recovery…"
[2025-01-15T14:32:16+0530] [OK]    service=nginx    msg="RECOVERED — service is now active."
[2025-01-15T14:32:17+0530] [ERROR] service=mysql    msg="FAILED — service still inactive after restart."
```

---

## 📊 Sample Output

```
╔══════════════════════════════════════════════╗
║       🩺  Service Health Monitor             ║
╚══════════════════════════════════════════════╝
  User    : priyanshu@Priyanshu
  Date    : Wednesday, 15 January 2025  14:32:08

╔══════════════════════════════════════════════╗
║           📊  Monitoring Summary             ║
╠══════════════════════════════════════════════╣
║  Metric                   Count              ║
╠══════════════════════════════════════════════╣
║  Total Checked                3              ║
║  Healthy                      2              ║
║  Recovered                    1              ║
║  Failed                       0              ║
╚══════════════════════════════════════════════╝
```

---

## 🛠️ Requirements

- Linux OS (Ubuntu/Debian recommended)
- `systemctl` (systemd-based system)
- Bash 4.0+
- `sudo` access (for restarting services and writing logs)

---

## 👤 Author

**Priyanshu Pandey**  
GitHub: [@priyanshupandeyyy](https://github.com/priyanshupandeyyy)
