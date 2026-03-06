# EasyInstall v5.6 - Quick Start Guide

## 🚀 **5-Minute Quick Start Guide**

This guide will teach you how to set up your first WordPress site with EasyInstall in just 5 minutes.

---

## 📋 **Prerequisites**

- **Server**: Debian 10+ or Ubuntu 20.04+ (fresh VPS recommended)
- **Root Access**: `root` or `sudo` access
- **Domain**: Optional (works with IP address too)
- **SSH Client**: PuTTY (Windows) or Terminal (Mac/Linux)

---

## ⚡ **Step 1: Connect to Your Server**

```bash
ssh root@your-server-ip
# or
ssh username@your-server-ip
```

---

## ⚡ **Step 2: Download and Run EasyInstall**

### **One-Line Install (Easiest)**
```bash
curl -sSL https://raw.githubusercontent.com/yourusername/easyinstall/main/easyinstall.sh | sudo bash
```

### **Or Clone from Git**
```bash
git clone https://github.com/yourusername/easyinstall.git
cd easyinstall
sudo chmod +x easyinstall.sh
sudo ./easyinstall.sh
```

**⏱️ Installation Time**: 5-10 minutes (depends on server speed)

---

## ⚡ **Step 3: Create Your First WordPress Site**

### **Option A: Traditional WordPress (Separate Redis per site)**
```bash
easyinstall wp example.com
```

**What happens:**
- ✅ WordPress files installed in `/var/www/html/example.com`
- ✅ Separate Redis instance created on port `6379`
- ✅ MySQL database created with secure password
- ✅ Nginx configuration created
- ✅ Credentials saved in `/root/example.com-credentials.txt`

**Access your site:** `http://example.com/wp-admin/install.php`

---

### **Option B: WordPress with Docker**
```bash
easyinstall wp-docker example.com
```

**What happens:**
- ✅ Docker containers for WordPress, MySQL, Redis, Nginx
- ✅ Site available on port `8080` (or next available)
- ✅ Isolated environment
- ✅ Easy to backup and restore

**Access your site:** `http://your-server-ip:8080`

---

### **Option C: WordPress with SSL (HTTPS)**
```bash
# Traditional with SSL
easyinstall wp example.com --ssl

# Docker with SSL
easyinstall wp-docker example.com --ssl
```

**What happens:**
- ✅ Free Let's Encrypt SSL certificate
- ✅ Auto-renewal configured
- ✅ HTTPS enabled site

**Access your site:** `https://example.com`

---

## ⚡ **Step 4: Verify Installation**

### **List all sites**
```bash
easyinstall list
```

**Output example:**
```
📋 Traditional Websites (port 80) with Redis:
  • http://example.com (Redis port: 6379)
  • http://testsite.com (Redis port: 6380)

🐳 Docker Sites:
  • dockersite.com - http://192.168.1.100:8080 (Redis in Docker)
```

### **Check Redis instances**
```bash
easyinstall redis-status
```

**Output example:**
```
=== Redis Instances Status ===
✓ Main Redis (port 6379): Running
✓ Site example-com (port 6379): Running
✓ Site testsite-com (port 6380): Running
```

### **Check system status**
```bash
easyinstall status
```

---

## ⚡ **Step 5: Complete WordPress Setup**

1. **Open your browser** and go to your site URL:
   - Traditional: `http://example.com/wp-admin/install.php`
   - Docker: `http://your-server-ip:8080/wp-admin/install.php`

2. **Select language** (English or your preferred language)

3. **Fill in WordPress details:**
   - Site Title: Your site name
   - Username: Choose admin username
   - Password: Use strong password (or auto-generated)
   - Email: Your email address

4. **Click "Install WordPress"**

5. **Login** with your credentials

---

## ⚡ **Useful Commands for Daily Use**

### **Site Management**
```bash
# List all sites
easyinstall list

# Delete a site (removes files, database, and Redis)
easyinstall delete example.com

# Enable SSL for existing site
easyinstall ssl example.com
```

### **Redis Management**
```bash
# Show all Redis instances
easyinstall redis-status

# List Redis ports in use
easyinstall redis-ports

# Restart Redis for a specific site
easyinstall redis-restart example.com

# Access Redis CLI for a site
easyinstall redis-cli example.com
```

### **Docker Management**
```bash
# List Docker sites with ports
easyinstall docker-list

# View Docker logs
easyinstall docker-logs example.com

# Restart Docker site
easyinstall docker-restart example.com

# Shell into WordPress container
easyinstall docker-shell example.com
```

### **Monitoring**
```bash
# Live system monitoring (updates every 5 seconds)
easyinstall monitor

# Open Netdata dashboard (press Ctrl+C to exit)
easyinstall netdata
# Then visit: http://your-server-ip:19999
```

### **Backups**
```bash
# Create daily backup
easyinstall backup

# Create weekly backup
easyinstall backup weekly

# Backup specific Docker site
easyinstall backup-docker example.com
```

---

## 🎯 **Quick Examples for Different Scenarios**

### **Scenario 1: Personal Blog**
```bash
# Simple WordPress with SSL
easyinstall wp myblog.com --ssl
```

### **Scenario 2: Multiple Client Sites**
```bash
# First client (Redis port 6379)
easyinstall wp client1.com

# Second client (Redis port 6380)
easyinstall wp client2.com

# Third client (Redis port 6381)
easyinstall wp client3.com
```

### **Scenario 3: Development Environment**
```bash
# Docker with PHP 8.3 and MySQL 8.0
easyinstall wp-docker devsite.com --php=8.3 --mysql=8.0
```

### **Scenario 4: Staging Site**
```bash
# Create staging for production site
easyinstall staging create example.com

# Test changes on staging
# http://staging.example.com

# Push to production when ready
easyinstall staging sync example.com
```

---

## 🔧 **Troubleshooting Common Issues**

### **Issue: Site not loading**
```bash
# Check Nginx status
systemctl status nginx

# Check PHP-FPM
systemctl status php8.2-fpm

# Check Redis
easyinstall redis-status

# View error logs
tail -f /var/log/nginx/example.com.error.log
```

### **Issue: Redis not working**
```bash
# Check Redis instance
systemctl status redis-example-com

# View Redis logs
journalctl -u redis-example-com -f

# Test Redis connection
redis-cli -p 6379 ping
# Should return: PONG
```

### **Issue: Database connection error**
```bash
# Check MySQL
systemctl status mysql

# Test database connection
mysql -u root -e "SHOW DATABASES;"

# Check WordPress database exists
mysql -e "SHOW DATABASES LIKE 'wp_example_com';"
```

### **Issue: Permission denied**
```bash
# Fix permissions
chown -R www-data:www-data /var/www/html/example.com
chmod -R 755 /var/www/html/example.com
```

---

## 📊 **Monitoring Your Server**

### **Netdata Dashboard**
Access your Netdata dashboard for real-time monitoring:
```
http://your-server-ip:19999
```

### **Custom Monitoring Script**
```bash
# Run live monitor
easyinstall monitor
```

---

## 💾 **Backup and Restore**

### **Create Backup**
```bash
# Automatic daily backup (runs at 2 AM)
easyinstall backup daily

# Manual backup
easyinstall backup
```

### **Restore from Backup**
```bash
# One-click restore (coming soon)
easyinstall restore example.com latest
```

---

## 🎉 **Congratulations!**

You have successfully:
- ✅ Installed EasyInstall
- ✅ Created your first WordPress site
- ✅ Learned basic management commands
- ✅ Set up monitoring and backups

### **Next Steps:**
1. Explore more commands: `easyinstall help`
2. Set up SSL for your sites
3. Configure staging sites for testing
4. Set up cloud backups (Google Drive/AWS S3)
5. Integrate with Git for version control

---

## 📚 **Additional Resources**

- [Complete Commands Guide](COMMANDS.md)
- [Redis Setup Guide](REDIS-SETUP.md)
- [Docker Configuration](DOCKER-SETUP.md)
- [SSL Setup Guide](SSL-SETUP.md)
- [Backup & Restore Guide](BACKUP-RESTORE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

---

## ☕ **Support**

If EasyInstall saved you time, consider buying me a coffee:

[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue)](https://paypal.me/yourusername)

---

**Happy Hosting!** 🚀