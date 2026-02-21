# 🚀 EasyInstall Enterprise Stack

## Ultra-Optimized 512MB VPS → Enterprise Grade Hosting Engine Fully Tested on Debian 11,12 & Ubuntu 24.04 , 22 LTS, Try Your self in Other Distro.Linux Mint and Pop!_OS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Production Ready](https://img.shields.io/badge/Production-Ready-brightgreen.svg)]()
[![512MB Optimized](https://img.shields.io/badge/Optimized-512MB%20VPS-blue.svg)]()

---
### Run this Command On Your VPS 
#  '   wget -qO- install.easyinstall.site | bash '

# EasyInstall Enterprise Stack v2.1

## 🚀 **Ultra-Optimized WordPress Hosting Engine for 512MB VPS**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Production Ready](https://img.shields.io/badge/Production-Ready-brightgreen)](https://github.com/)
[![WordPress](https://img.shields.io/badge/WordPress-Optimized-blue)](https://wordpress.org)
[![PHP](https://img.shields.io/badge/PHP-8.x-purple)](https://php.net)

---

## 📋 **Table of Contents**
- [Overview](#-overview)
- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Command Reference](#-command-reference)
- [Architecture](#-architecture)
- [Performance Optimization](#-performance-optimization)
- [Security Features](#-security-features)
- [Backup & Recovery](#-backup--recovery)
- [Multi-Site Management](#-multi-site-management)
- [Monitoring](#-monitoring)
- [CDN Integration](#-cdn-integration)
- [Email Configuration](#-email-configuration)
- [Troubleshooting](#-troubleshooting)
- [FAQ](#-faq)
- [Support](#-support)
- [License](#-license)

---

## 🎯 **Overview**

EasyInstall is a **production-ready, enterprise-grade WordPress hosting stack** specifically optimized for **512MB RAM VPS**. It transforms a basic virtual private server into a high-performance WordPress hosting engine with automatic optimization, security hardening, and comprehensive management tools.

**Why EasyInstall?**
- 🚀 **10x Performance** - Optimized for low-memory VPS
- 🔒 **Enterprise Security** - Built-in firewall, fail2ban, SSL
- 💾 **Automated Backups** - Daily/weekly/monthly with auto-cleanup
- 📊 **Real-time Monitoring** - Netdata + custom alerts
- 🌐 **Multi-site Support** - Host multiple WordPress sites
- ☁️ **CDN Ready** - Cloudflare, BunnyCDN integration
- 📧 **Email Ready** - Transactional emails and alerts

---

## ✨ **Features**

### **Core Features**
- ✅ Automatic PHP 8.x installation (latest stable)
- ✅ Nginx with FastCGI cache
- ✅ MariaDB with low-memory optimization
- ✅ Redis object cache
- ✅ Let's Encrypt SSL auto-renewal
- ✅ UFW Firewall configuration
- ✅ Fail2ban protection
- ✅ WordPress latest version

### **Advanced Features**
- ✅ **Adaptive Resource Management** - Auto-configures based on RAM
- ✅ **Kernel Tuning** - Network and filesystem optimization
- ✅ **Swap Configuration** - Dynamic swap size based on RAM
- ✅ **OPcache Enabled** - PHP bytecode caching
- ✅ **Automated Backups** - Daily, weekly, monthly with retention
- ✅ **Multi-site Panel** - Host unlimited WordPress sites
- ✅ **CDN Integration** - Cloudflare, BunnyCDN, QuickCache
- ✅ **Email Service** - Local Postfix with transactional support
- ✅ **Monitoring** - Netdata + custom resource checks
- ✅ **Performance Reports** - Generate detailed system reports

---

## 💻 **System Requirements**

### **Minimum Requirements**
| Component | Requirement |
|-----------|-------------|
| **RAM** | 512 MB |
| **CPU** | 1 Core |
| **Disk** | 10 GB |
| **OS** | Ubuntu 20.04+ / Debian 11+ |

### **Recommended**
| Component | Recommendation |
|-----------|----------------|
| **RAM** | 1 GB+ |
| **CPU** | 2 Cores |
| **Disk** | 20 GB SSD |
| **OS** | Ubuntu 22.04 LTS |

---

## 🚀 **Installation**

### **One-Line Installation**
```bash
curl -sSL https://raw.githubusercontent.com/sugan0927/easyinstall/main/easyinstall.sh | bash
```

### **Manual Installation**
```bash
# Download the script
wget https://raw.githubusercontent.com/sugan0927/easyinstall/main/easyinstall.sh

# Make it executable
chmod +x easyinstall.sh

# Run as root
sudo ./easyinstall.sh
```

### **Installation Process**
The script automatically:
1. 📊 Detects system resources
2. 🔧 Configures swap space
3. ⚙️ Applies kernel optimizations
4. 📦 Installs all required packages
5. 🔐 Secures database
6. ⚡ Optimizes PHP-FPM
7. 🚀 Configures Nginx with cache
8. 📝 Installs WordPress
9. 💾 Sets up backup system
10. 📊 Configures monitoring
11. ☁️ Adds CDN tools
12. 📧 Configures email

---

## ⚡ **Quick Start**

### **After Installation**
```bash
# Check system status
easyinstall status

# View installation info
cat /root/easyinstall-info.txt

# Access WordPress
http://your-server-ip
```

### **Basic Workflow**
```bash
# 1. Point your domain to server IP
# 2. Add domain to WordPress
easyinstall domain example.com

# 3. Install SSL certificate
easyinstall ssl example.com

# 4. Enable Redis cache
easyinstall redis enable

# 5. View performance report
easyinstall report
```

---

## 📚 **Command Reference**

### **Main Command Structure**
```bash
easyinstall [category] [command] [options]
```

### **Complete Command List**

#### 🌐 **Domain & SSL**
| Command | Description |
|---------|-------------|
| `easyinstall domain <domain>` | Change WordPress domain |
| `easyinstall domain <domain> -php*v=8.2 -ssl=on -cache=on -clearcache` | Advanced domain update |
| `easyinstall ssl <domain> [email]` | Install SSL + plugins |
| `easyinstall migrate <domain>` | Migrate from IP to domain |

#### 💾 **Backup & Restore**
| Command | Description |
|---------|-------------|
| `easyinstall backup [daily\|weekly\|monthly]` | Create backup |
| `easyinstall restore` | Restore from backup |
| `easyinstall db backup` | Database backup only |
| `easyinstall db restore <file>` | Restore database |

#### 📊 **Monitoring & Reports**
| Command | Description |
|---------|-------------|
| `easyinstall status` | System status |
| `easyinstall report` | Performance report |
| `easyinstall health` | Health check |

#### ☁️ **CDN Integration**
| Command | Description |
|---------|-------------|
| `easyinstall cdn cloudflare <domain> <key> <email>` | Cloudflare setup |
| `easyinstall cdn bunnycdn <domain> <key> <zone>` | BunnyCDN setup |
| `easyinstall cdn quickcache` | Enable QuickCache |

#### 📧 **Email**
| Command | Description |
|---------|-------------|
| `easyinstall mail config <email>` | Set admin email |
| `easyinstall mail send <to> <subject> <body>` | Send email |
| `easyinstall mail alert <message>` | Send alert |

#### 🏢 **Multi-site**
| Command | Description |
|---------|-------------|
| `easyinstall site create <domain>` | Create new site |
| `easyinstall site delete <domain>` | Delete site |
| `easyinstall site list` | List all sites |
| `easyinstall site ssl <domain>` | Add SSL to site |

#### ⚡ **Performance**
| Command | Description |
|---------|-------------|
| `easyinstall cache clear` | Clear FastCGI cache |
| `easyinstall redis enable` | Enable Redis cache |
| `easyinstall optimize` | Optimize system |
| `easyinstall reinstall` | Reinstall WordPress |

#### 🔧 **Maintenance**
| Command | Description |
|---------|-------------|
| `easyinstall update` | Update system |
| `easyinstall upgrade` | Upgrade packages |
| `easyinstall clean` | Clean temp files |
| `easyinstall logs [service]` | View logs |
| `easyinstall restart [service]` | Restart services |

#### 🔐 **Security**
| Command | Description |
|---------|-------------|
| `easyinstall firewall status` | Firewall status |
| `easyinstall fail2ban status` | Fail2ban status |
| `easyinstall ssl renew` | Renew SSL |
| `easyinstall ssl list` | List certificates |

#### 🗄️ **Database**
| Command | Description |
|---------|-------------|
| `easyinstall db list` | List databases |
| `easyinstall db optimize` | Optimize database |
| `easyinstall db credentials` | Show credentials |

---

## 🏗️ **Architecture**

### **Component Stack**
```
┌─────────────────────────────────────┐
│         WordPress                    │
├─────────────────────────────────────┤
│         Nginx + FastCGI Cache        │
├─────────────────────────────────────┤
│         PHP-FPM + OPcache            │
├─────────────────────────────────────┤
│    MariaDB    │    Redis             │
├─────────────────────────────────────┤
│    Ubuntu/Debian OS                  │
└─────────────────────────────────────┘
```

### **Resource Allocation (512MB VPS)**
```
RAM Distribution:
├── 80MB  - Nginx + Cache
├── 120MB - PHP-FPM (4 processes)
├── 80MB  - MariaDB
├── 30MB  - Redis
├── 30MB  - System services
└── 172MB - Free/Buffer

Swap:
└── 1GB - Based on RAM size
```

---

## ⚙️ **Performance Optimization**

### **Auto-Tuning Features**
The script automatically optimizes based on your RAM:

| RAM | PHP Children | Cache Size | Swappiness |
|-----|--------------|------------|------------|
| 512MB | 4 | 100MB | 60 |
| 1GB | 8 | 200MB | 50 |
| 2GB+ | 16 | 500MB | 40 |

### **Enabled Optimizations**
- ✅ Nginx FastCGI caching
- ✅ PHP OPcache
- ✅ Redis object cache
- ✅ MariaDB query cache
- ✅ Kernel network tuning
- ✅ Filesystem optimizations
- ✅ Swap tuning

---

## 🔒 **Security Features**

### **Built-in Security**
- ✅ **UFW Firewall** - Only ports 22, 80, 443 open
- ✅ **Fail2ban** - Protects against brute force
- ✅ **SSL/TLS** - Let's Encrypt auto-renewal
- ✅ **MySQL Secure Installation** - Removes test databases
- ✅ **WordPress Hardening** - Disables file editing, limits revisions
- ✅ **Nginx Security Headers** - X-Frame-Options, XSS protection
- ✅ **Hidden Files Protection** - Denies access to .htaccess, .git
- ✅ **Rate Limiting** - Prevents DDoS attacks

### **Security Commands**
```bash
# Check security status
easyinstall firewall status
easyinstall fail2ban status

# Unblock IP
easyinstall fail2ban unban 1.2.3.4

# Add firewall rule
easyinstall firewall allow 8080
```

---

## 💾 **Backup & Recovery**

### **Backup Types**
| Type | Frequency | Retention |
|------|-----------|-----------|
| Daily | Every day | 7 days |
| Weekly | Every Sunday | 30 days |
| Monthly | 1st of month | 1 year |

### **Backup Contents**
- ✅ WordPress database (SQL)
- ✅ WordPress files (wp-content, etc.)
- ✅ Nginx configuration
- ✅ SSL certificates

### **Backup Commands**
```bash
# Create backups
easyinstall backup daily
easyinstall backup weekly
easyinstall backup monthly

# Restore from backup
easyinstall restore

# List backups
ls -la /backups/daily/
```

### **Automatic Backup Schedule**
```cron
0 2 * * * root easyinstall backup daily     # 2 AM daily
0 3 * * 0 root easyinstall backup weekly    # 3 AM Sunday
0 4 1 * * root easyinstall backup monthly   # 4 AM 1st of month
```

---

## 🌐 **Multi-Site Management**

### **Features**
- ✅ Host unlimited WordPress sites
- ✅ Separate databases per site
- ✅ Isolated file systems
- ✅ Individual SSL certificates
- ✅ Per-site caching

### **Multi-Site Commands**
```bash
# Create new site
easyinstall site create testsite.com

# List all sites
easyinstall site list

# Add SSL to site
easyinstall site ssl testsite.com

# Delete site
easyinstall site delete testsite.com
```

### **Site Directory Structure**
```
/var/www/sites/
├── example.com/
│   ├── public/           # WordPress files
│   ├── logs/             # Access & error logs
│   ├── backups/          # Site backups
│   └── site-info.txt     # Database credentials
├── testsite.com/
└── blog.example.com/
```

---

## 📊 **Monitoring**

### **Monitoring Tools**
- ✅ **Netdata** - Real-time performance monitoring
- ✅ **Custom Resource Checks** - Every 15 minutes
- ✅ **Email Alerts** - For critical issues
- ✅ **Performance Reports** - Daily/weekly summaries

### **Monitored Metrics**
| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Load | > 2.0 | Email alert |
| Memory | > 90% | Email alert |
| Disk | > 85% | Auto-clean + alert |
| SSL Expiry | < 7 days | Email alert |
| Service Status | Down | Auto-restart |

### **Monitoring Commands**
```bash
# View real-time stats
easyinstall status

# Generate report
easyinstall report

# Access Netdata dashboard
http://your-server-ip:19999
```

### **Sample Performance Report**
```
📊 EasyInstall Performance Report
==================================

System Uptime: 15 days

CPU Usage: 12%
Load average: 0.45, 0.32, 0.28

Memory Usage: 342MB/512MB (66%)
Swap Usage: 120MB/1GB

Disk Usage: 4.2GB/20GB (21%)

Service Status:
✅ nginx: active
✅ php8.2-fpm: active
✅ mariadb: active
✅ redis-server: active

Cache Statistics:
Nginx Cache: 45MB
Redis Memory: 12MB

Database Size: 85MB
Latest Backup: 20240115-023045 (125MB)
```

---

## ☁️ **CDN Integration**

### **Supported CDNs**
- ✅ **Cloudflare** - Full API integration
- ✅ **BunnyCDN** - Storage zone support
- ✅ **QuickCache** - Built-in WordPress plugin

### **CDN Commands**
```bash
# Cloudflare setup
easyinstall cdn cloudflare example.com your-api-key admin@example.com

# BunnyCDN setup
easyinstall cdn bunnycdn example.com your-api-key storage-zone

# QuickCache setup
easyinstall cdn quickcache

# Check CDN status
easyinstall cdn status
```

### **CDN Benefits**
- 🚀 Faster global loading
- 🔒 DDoS protection
- 💾 Bandwidth savings
- 🌍 Edge caching

---

## 📧 **Email Configuration**

### **Email Features**
- ✅ Local Postfix server
- ✅ Transactional emails
- ✅ Alert notifications
- ✅ WordPress email support

### **Email Commands**
```bash
# Set admin email
easyinstall mail config admin@example.com

# Send email
easyinstall mail send user@example.com "Subject" "Message body"

# Send alert
easyinstall mail alert "High CPU usage detected"

# Check email status
easyinstall mail status
```

### **Email Configuration**
```php
// WordPress will automatically use local mail
// No additional SMTP setup required
```

---

## 🔧 **Troubleshooting**

### **Common Issues & Solutions**

#### **1. WordPress White Screen**
```bash
# Enable debug mode
easyinstall debug enable

# Check error logs
easyinstall logs php

# Increase memory limit
easyinstall domain example.com -php*v=8.2
```

#### **2. SSL Installation Fails**
```bash
# Check DNS propagation
dig example.com

# Ensure port 80 is open
easyinstall firewall status

# Manual SSL installation
certbot --nginx -d example.com
```

#### **3. High Memory Usage**
```bash
# Check memory usage
easyinstall status

# Clear cache
easyinstall cache clear

# Optimize database
easyinstall db optimize

# Reduce PHP workers (edit manually)
nano /etc/php/8.2/fpm/pool.d/www.conf
```

#### **4. Database Connection Issues**
```bash
# Check MySQL status
systemctl status mariadb

# View MySQL logs
easyinstall logs mysql

# Repair database
mysqlcheck -r --all-databases
```

### **Logs Location**
| Service | Log Location |
|---------|--------------|
| Nginx | `/var/log/nginx/` |
| PHP-FPM | `/var/log/php*-fpm.log` |
| MySQL | `/var/log/mysql/error.log` |
| WordPress | `/var/www/html/wordpress/wp-content/debug.log` |
| Backup | `/backups/logs/` |
| System | `journalctl -xe` |

---

## ❓ **FAQ**

### **General Questions**

**Q: Can I run this on 512MB RAM VPS?**
A: Yes! The script is specifically optimized for 512MB VPS and includes swap configuration to handle memory constraints.

**Q: Which PHP version is installed?**
A: The latest PHP 8.x version available (8.3, 8.2, or 8.1). You can switch versions anytime with `easyinstall domain -php*v=8.2`.

**Q: Is this production ready?**
A: Absolutely! The script includes enterprise-grade security, backups, monitoring, and optimization features.

**Q: Can I host multiple WordPress sites?**
A: Yes! Use `easyinstall site create domain.com` to add unlimited sites.

### **Technical Questions**

**Q: How much disk space do I need?**
A: Minimum 10GB, recommended 20GB for backups and multiple sites.

**Q: Does it support Let's Encrypt SSL?**
A: Yes, automatic SSL with auto-renewal via `easyinstall ssl domain.com`.

**Q: How are backups handled?**
A: Automated daily, weekly, monthly backups with 7/30/365 day retention. Stored in `/backups/`.

**Q: Can I restore from backup?**
A: Yes! Use `easyinstall restore` and select from available backups.

**Q: Is there a control panel?**
A: The script provides CLI management commands. Netdata dashboard is available at port 19999 for monitoring.

### **Security Questions**

**Q: Is the firewall configured?**
A: Yes, UFW is configured with only SSH (22), HTTP (80), and HTTPS (443) ports open.

**Q: How is WordPress secured?**
A: File editing disabled, limited revisions, secure salts, hidden files protection, and security headers.

**Q: What about DDoS protection?**
A: Fail2ban protects against brute force, and Nginx has rate limiting configured.

**Q: How are updates handled?**
A: Use `easyinstall update` for system updates and `easyinstall wp update` for WordPress.

### **Performance Questions**

**Q: How fast is it?**
A: With FastCGI cache and Redis, WordPress loads in under 500ms even on 512MB VPS.

**Q: Can I clear cache?**
A: Yes! `easyinstall cache clear` clears FastCGI cache instantly.

**Q: How to optimize database?**
A: `easyinstall db optimize` runs MariaDB optimization.

**Q: Does it support CDN?**
A: Yes! Cloudflare, BunnyCDN, and QuickCache integration available.

---

## 🆘 **Support**

### **Get Help**
```bash
# Show all commands
easyinstall help

# Show specific command help
easyinstall domain --help

# Check system status
easyinstall status

# View logs
easyinstall logs
```

### **Documentation**
- 📚 [Full Command Reference](#-command-reference)
- 🔧 [Troubleshooting Guide](#-troubleshooting)
- ❓ [FAQ](#-faq)

### **Community**
- 🐛 Report issues on GitHub
- 💬 Join our Discord
- 📧 Email: support@easyinstall.io

---

## 🤝 **Contributing**

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 EasyInstall

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files...
```

---

## 🙏 **Acknowledgments**

- [Ondřej Surý](https://deb.sury.org/) for PHP packages
- [Let's Encrypt](https://letsencrypt.org/) for free SSL
- [WordPress](https://wordpress.org/) for the best CMS
- [Netdata](https://www.netdata.cloud/) for monitoring
- All contributors and users

---

## 📞 **Contact**

- **Author**: Sugan dodRai
- **Email**: sdsugans018@gmail.com
- **PayPal**: [https://paypal.me/sugandodrai](https://paypal.me/sugandodrai)
- **GitHub**: [https://github.com/sugandodrai](https://github.com/sugandodrai)

---

## 🌟 **Star History**

If you find this project useful, please give it a star on GitHub! It helps others discover it.

---

## 📊 **Project Status**

- ✅ Production Ready
- ✅ Active Development
- ✅ Community Supported
- ✅ Regular Updates

---

**Made with ❤️ for the WordPress community**

[⬆ Back to Top](#easyinstall-enterprise-stack-v21)
