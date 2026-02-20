#!/bin/bash

set -e

# ============================================
# EasyInstall Enterprise Stack v2.1
# Ultra-Optimized 512MB VPS → Enterprise Grade Hosting Engine
# Complete Production Ready Version with All Features
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 EasyInstall Enterprise Stack v2.1${NC}"
echo -e "${GREEN}📦 Complete Production Ready WordPress Hosting Engine${NC}"
echo ""

# Root check
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Please run as root${NC}"
  exit 1
fi

# ============================================
# System Detection & Optimization
# ============================================
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
TOTAL_CORES=$(nproc)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
OS_VERSION=$(lsb_release -sc)

echo -e "${YELLOW}📊 System Information:${NC}"
echo "   • RAM: ${TOTAL_RAM}MB"
echo "   • CPU Cores: ${TOTAL_CORES}"
echo "   • IP Address: ${IP_ADDRESS}"
echo "   • OS: Ubuntu/Debian ${OS_VERSION}"
echo ""

# ============================================
# Adaptive Swap Configuration
# ============================================
setup_swap() {
    echo -e "${YELLOW}📀 Configuring swap space...${NC}"
    
    if [ ! -f /swapfile ]; then
        if [ "$TOTAL_RAM" -le 512 ]; then
            SWAPSIZE=1G
            SWAPPINESS=60
        elif [ "$TOTAL_RAM" -le 1024 ]; then
            SWAPSIZE=2G
            SWAPPINESS=50
        else
            SWAPSIZE=4G
            SWAPPINESS=40
        fi
        
        fallocate -l $SWAPSIZE /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        
        # Optimize swap usage
        echo "vm.swappiness=$SWAPPINESS" >> /etc/sysctl.conf
        echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
        
        echo -e "${GREEN}   ✅ Swap created: $SWAPSIZE${NC}"
    else
        echo -e "   ⚠️  Swap already exists"
    fi
}

# ============================================
# Kernel Tuning
# ============================================
kernel_tuning() {
    echo -e "${YELLOW}⚙️  Applying kernel optimizations...${NC}"
    
    cat > /etc/sysctl.d/99-easyinstall.conf <<EOF
# Network security
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000

# Connection optimization
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65000

# Memory optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Security
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# File system
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
EOF

    sysctl -p /etc/sysctl.d/99-easyinstall.conf
    echo -e "${GREEN}   ✅ Kernel tuning applied${NC}"
}

# ============================================
# Install Required Packages (with newest PHP)
# ============================================
install_packages() {
    echo -e "${YELLOW}📦 Installing enterprise stack with latest PHP...${NC}"
    
    # Update package list
    apt update
    
    # Install prerequisites
    apt install -y software-properties-common curl wget gnupg2 ca-certificates lsb-release \
        apt-transport-https bc
    
    # Alternative method to add ondrej/php repository (more reliable)
    echo -e "${YELLOW}   📌 Adding PHP repository (ondrej/php)...${NC}"
    
    # Method 1: Try using add-apt-repository with retry
    if ! add-apt-repository -y ppa:ondrej/php 2>/dev/null; then
        echo -e "${YELLOW}   ⚠️ add-apt-repository failed, trying alternative method...${NC}"
        
        # Method 2: Manual repository addition
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php || {
            # Method 3: Direct repository setup
            echo -e "${YELLOW}   📌 Using direct repository setup...${NC}"
            
            # Install GPG key
            wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg 2>/dev/null || \
            curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
            
            # Add repository
            echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
        }
    fi
    
    # Update package list again
    apt update
    
    # Get latest PHP version
    PHP_VERSION=""
    for version in 8.3 8.2 8.1 8.0; do
        if apt-cache show php${version}-fpm >/dev/null 2>&1; then
            PHP_VERSION="php${version}"
            echo -e "${GREEN}   ✅ Found PHP ${version}${NC}"
            break
        fi
    done
    
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION="php8.2"  # Fallback
        echo -e "${YELLOW}   ⚠️ Using fallback PHP 8.2${NC}"
    fi
    
    echo -e "${YELLOW}   📌 Installing PHP ${PHP_VERSION}...${NC}"
    
    apt install -y nginx mariadb-server ${PHP_VERSION}-fpm ${PHP_VERSION}-mysql \
        ${PHP_VERSION}-cli ${PHP_VERSION}-curl ${PHP_VERSION}-xml ${PHP_VERSION}-mbstring \
        ${PHP_VERSION}-zip ${PHP_VERSION}-gd ${PHP_VERSION}-imagick ${PHP_VERSION}-opcache \
        ${PHP_VERSION}-redis ${PHP_VERSION}-intl \
        redis-server ufw fail2ban curl wget unzip openssl \
        certbot python3-certbot-nginx \
        htop neofetch git cron dnsutils \
        automysqlbackup rclone netdata
        
    echo -e "${GREEN}   ✅ All packages installed with PHP ${PHP_VERSION}${NC}"
}

# ============================================
# Database Security & Configuration
# ============================================
setup_database() {
    echo -e "${YELLOW}🔐 Securing database...${NC}"
    
    # Secure installation
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Create WordPress database
    DB_NAME="wordpress_$(openssl rand -hex 4)"
    DB_USER="wpuser_$(openssl rand -hex 4)"
    DB_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c20)
    
    mysql -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Optimize MariaDB for low memory
    cat > /etc/mysql/mariadb.conf.d/99-easyinstall.cnf <<EOF
[mysqld]
performance_schema = off
skip-name-resolve
table_open_cache = 400
thread_cache_size = 16
query_cache_type = 0
query_cache_size = 0
tmp_table_size = 16M
max_heap_table_size = 16M
max_connections = 50
EOF
    
    systemctl restart mariadb
    
    echo -e "${GREEN}   ✅ Database configured${NC}"
}

# ============================================
# PHP-FPM Optimization
# ============================================
optimize_php() {
    echo -e "${YELLOW}⚡ Optimizing PHP-FPM...${NC}"
    
    # Wait for PHP to be fully installed
    sleep 2
    
    # Get PHP version with fallback
    if command -v php >/dev/null 2>&1; then
        PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
    fi
    
    # If PHP_VERSION is empty, try to detect from installed packages
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION=$(ls /etc/php/ 2>/dev/null | head -1)
    fi
    
    # Final fallback
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION="8.2"
    fi
    
    PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
    PHP_POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    
    # Check if files exist
    if [ ! -f "$PHP_INI" ] || [ ! -f "$PHP_POOL" ]; then
        echo -e "${YELLOW}   ⚠️ PHP config files not found, trying to locate...${NC}"
        
        # Try to find PHP version from directories
        for dir in /etc/php/*; do
            if [ -d "$dir" ]; then
                PHP_VERSION=$(basename "$dir")
                PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
                PHP_POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
                if [ -f "$PHP_INI" ] && [ -f "$PHP_POOL" ]; then
                    echo -e "${GREEN}   ✅ Found PHP ${PHP_VERSION} configs${NC}"
                    break
                fi
            fi
        done
    fi
    
    # Calculate optimal settings based on RAM
    if [ "$TOTAL_RAM" -le 512 ]; then
        MAX_CHILDREN=4
        START_SERVERS=2
        MIN_SPARE=1
        MAX_SPARE=3
        MEMORY_LIMIT="128M"
    elif [ "$TOTAL_RAM" -le 1024 ]; then
        MAX_CHILDREN=8
        START_SERVERS=3
        MIN_SPARE=2
        MAX_SPARE=6
        MEMORY_LIMIT="256M"
    else
        MAX_CHILDREN=16
        START_SERVERS=4
        MIN_SPARE=2
        MAX_SPARE=8
        MEMORY_LIMIT="512M"
    fi
    
    # Update PHP-FPM pool if file exists
    if [ -f "$PHP_POOL" ]; then
        sed -i "s/^pm.max_children =.*/pm.max_children = ${MAX_CHILDREN}/" $PHP_POOL 2>/dev/null || true
        sed -i "s/^pm.start_servers =.*/pm.start_servers = ${START_SERVERS}/" $PHP_POOL 2>/dev/null || true
        sed -i "s/^pm.min_spare_servers =.*/pm.min_spare_servers = ${MIN_SPARE}/" $PHP_POOL 2>/dev/null || true
        sed -i "s/^pm.max_spare_servers =.*/pm.max_spare_servers = ${MAX_SPARE}/" $PHP_POOL 2>/dev/null || true
    else
        echo -e "${YELLOW}   ⚠️ PHP-FPM pool file not found, skipping pool optimization${NC}"
    fi
    
    # Optimize PHP.ini if file exists
    if [ -f "$PHP_INI" ]; then
        sed -i "s/^memory_limit =.*/memory_limit = ${MEMORY_LIMIT}/" $PHP_INI 2>/dev/null || true
        sed -i "s/^max_execution_time =.*/max_execution_time = 300/" $PHP_INI 2>/dev/null || true
        sed -i "s/^max_input_time =.*/max_input_time = 300/" $PHP_INI 2>/dev/null || true
        sed -i "s/^post_max_size =.*/post_max_size = 64M/" $PHP_INI 2>/dev/null || true
        sed -i "s/^upload_max_filesize =.*/upload_max_filesize = 64M/" $PHP_INI 2>/dev/null || true
        
        # Enable OPcache (check if already exists)
        if ! grep -q "opcache.enable" "$PHP_INI"; then
            cat >> $PHP_INI <<EOF

; OPcache Settings
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF
        fi
    else
        echo -e "${YELLOW}   ⚠️ PHP.ini file not found, skipping PHP optimization${NC}"
    fi
    
    echo -e "${GREEN}   ✅ PHP optimized for ${TOTAL_RAM}MB RAM${NC}"
}

# ============================================
# Nginx with FastCGI Cache
# ============================================
configure_nginx() {
    echo -e "${YELLOW}🚀 Configuring Nginx with FastCGI cache...${NC}"
    
    # Get PHP version with fallback
    if command -v php >/dev/null 2>&1; then
        PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
    fi
    
    if [ -z "$PHP_VERSION" ]; then
        # Try to detect from installed packages
        PHP_VERSION=$(ls /etc/php/ 2>/dev/null | head -1)
    fi
    
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION="8.2"
    fi
    
    # Calculate cache size based on RAM
    if [ "$TOTAL_RAM" -le 512 ]; then
        CACHE_SIZE="100m"
        CACHE_INACTIVE="30m"
    elif [ "$TOTAL_RAM" -le 1024 ]; then
        CACHE_SIZE="200m"
        CACHE_INACTIVE="60m"
    else
        CACHE_SIZE="500m"
        CACHE_INACTIVE="120m"
    fi
    
    # Create cache directory with proper permissions
    mkdir -p /var/cache/nginx
    chown -R www-data:www-data /var/cache/nginx
    chmod -R 755 /var/cache/nginx
    
    # Check if PHP-FPM socket exists
    PHP_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"
    if [ ! -S "$PHP_SOCKET" ]; then
        # Try to find the correct socket
        for sock in /run/php/php*-fpm.sock; do
            if [ -S "$sock" ]; then
                PHP_SOCKET="$sock"
                echo -e "${YELLOW}   ✅ Found PHP socket: $sock${NC}"
                break
            fi
        done
    fi
    
    # Create main Nginx config with cache
    cat > /etc/nginx/sites-available/wordpress <<EOF
# FastCGI Cache Zone
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:${CACHE_SIZE} inactive=${CACHE_INACTIVE} max_size=${CACHE_SIZE};
fastcgi_cache_key "\$scheme\$request_method\$host\$request_uri";
fastcgi_cache_use_stale error timeout updating invalid_header http_500 http_503;
fastcgi_cache_lock on;
fastcgi_cache_valid 200 301 302 ${CACHE_INACTIVE};
fastcgi_cache_valid 404 1m;
fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

server {
    listen 80;
    listen [::]:80;
    
    server_name _;
    
    root /var/www/html/wordpress;
    index index.php index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Cache \$upstream_cache_status;
    
    # Logs
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;
    
    # Static files cache
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg|eot)$ {
        expires 365d;
        add_header Cache-Control "public, immutable";
    }
    
    # WordPress URLs
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP processing with FastCGI Cache
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCKET};
        
        # FastCGI Cache
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_methods GET HEAD;
        add_header X-Cache \$upstream_cache_status;
        
        # Skip cache for cookies
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        
        # Define cache skip conditions
        set \$skip_cache 0;
        if (\$request_method = POST) {
            set \$skip_cache 1;
        }
        if (\$query_string != "") {
            set \$skip_cache 1;
        }
        if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
            set \$skip_cache 1;
        }
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to sensitive files
    location ~ ^/(wp-config\.php|wp-config\.txt|readme\.html|license\.txt|wp-config-sample\.php) {
        deny all;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload
    nginx -t && systemctl restart nginx
    
    echo -e "${GREEN}   ✅ Nginx configured with FastCGI cache (${CACHE_SIZE})${NC}"
}

# ============================================
# WordPress Installation (Fixed permissions)
# ============================================
install_wordpress() {
    echo -e "${YELLOW}📝 Installing WordPress...${NC}"
    
    cd /var/www/html
    
    # Download WordPress
    if [ ! -f latest.zip ]; then
        curl -O https://wordpress.org/latest.zip
    fi
    
    # Extract
    unzip -o latest.zip
    
    # Create necessary directories with proper permissions
    mkdir -p wordpress/wp-content/upgrade
    mkdir -p wordpress/wp-content/plugins
    mkdir -p wordpress/wp-content/themes
    mkdir -p wordpress/wp-content/uploads
    mkdir -p wordpress/wp-content/cache
    
    # Set permissions BEFORE plugin installation
    chown -R www-data:www-data wordpress
    chmod -R 755 wordpress
    chmod -R 775 wordpress/wp-content
    chmod -R 775 wordpress/wp-content/upgrade
    chmod -R 775 wordpress/wp-content/plugins
    chmod -R 775 wordpress/wp-content/themes
    chmod -R 775 wordpress/wp-content/uploads
    
    # Configure wp-config
    cp wordpress/wp-config-sample.php wordpress/wp-config.php
    
    # Set database credentials
    sed -i "s/database_name_here/${DB_NAME}/" wordpress/wp-config.php
    sed -i "s/username_here/${DB_USER}/" wordpress/wp-config.php
    sed -i "s/password_here/${DB_PASS}/" wordpress/wp-config.php
    
    # Add security salts
    curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wordpress/wp-config.php
    
    # Add Redis cache support
    cat >> wordpress/wp-config.php <<EOF

/** Redis Cache */
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_CACHE', true);

/** Optimizations */
define('WP_MEMORY_LIMIT', '128M');
define('WP_MAX_MEMORY_LIMIT', '256M');
define('WP_POST_REVISIONS', 5);
define('EMPTY_TRASH_DAYS', 7);
define('DISALLOW_FILE_EDIT', true);

/* Ensure writable directories */
define('FS_METHOD', 'direct');
EOF
    
    # Final permission check
    chown -R www-data:www-data wordpress
    chmod -R 755 wordpress
    
    rm -f latest.zip
    
    echo -e "${GREEN}   ✅ WordPress installed with proper permissions${NC}"
}

# ============================================
# Redis Optimization
# ============================================
configure_redis() {
    echo -e "${YELLOW}⚡ Configuring Redis...${NC}"
    
    # Optimize Redis for low memory
    cat >> /etc/redis/redis.conf <<EOF

# EasyInstall Optimizations
maxmemory 128mb
maxmemory-policy allkeys-lru
save ""
appendonly no
EOF
    
    systemctl restart redis-server
    
    echo -e "${GREEN}   ✅ Redis optimized${NC}"
}

# ============================================
# Firewall & Security
# ============================================
setup_security() {
    echo -e "${YELLOW}🛡️  Configuring security...${NC}"
    
    # UFW rules
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    echo "y" | ufw enable
    
    # Fail2ban config
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true

[nginx-http-auth]
enabled = true

[nginx-botsearch]
enabled = true
EOF
    
    systemctl restart fail2ban
    
    echo -e "${GREEN}   ✅ Firewall and Fail2ban configured${NC}"
}

# ============================================
# Backup System Setup
# ============================================
setup_backups() {
    echo -e "${YELLOW}💾 Setting up automated backup system...${NC}"
    
    # Create backup directories
    mkdir -p /backups/{daily,weekly,monthly,scripts,logs}
    mkdir -p /root/.config/rclone
    
    # Create main backup script
    cat > /usr/local/bin/easy-backup <<'EOF'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKUP_TYPE="${1:-daily}"
BACKUP_ROOT="/backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_TYPE/$DATE"
LOG_FILE="$BACKUP_ROOT/logs/backup-$DATE.log"

# Load database credentials from WordPress config
if [ -f "/var/www/html/wordpress/wp-config.php" ]; then
    DB_NAME=$(grep DB_NAME /var/www/html/wordpress/wp-config.php | cut -d"'" -f4)
    DB_USER=$(grep DB_USER /var/www/html/wordpress/wp-config.php | cut -d"'" -f4)
    DB_PASS=$(grep DB_PASSWORD /var/www/html/wordpress/wp-config.php | cut -d"'" -f4)
else
    echo "WordPress config not found!"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Starting $BACKUP_TYPE backup..."

# Database backup
log_message "Backing up database: $DB_NAME"
mysqldump --opt --single-transaction --events --triggers --routines \
    -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_DIR/database.sql.gz"

if [ $? -eq 0 ]; then
    log_message "✅ Database backup completed: $(du -h $BACKUP_DIR/database.sql.gz | cut -f1)"
else
    log_message "❌ Database backup failed"
fi

# WordPress files backup
log_message "Backing up WordPress files"
tar -czf "$BACKUP_DIR/wordpress-files.tar.gz" \
    --exclude="*.log" \
    --exclude="cache/*" \
    --exclude="tmp/*" \
    -C /var/www/html wordpress 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    log_message "✅ Files backup completed: $(du -h $BACKUP_DIR/wordpress-files.tar.gz | cut -f1)"
else
    log_message "❌ Files backup failed"
fi

# Nginx config backup
log_message "Backing up Nginx configuration"
tar -czf "$BACKUP_DIR/nginx-config.tar.gz" -C /etc nginx 2>> "$LOG_FILE"

# Create backup info file
cat > "$BACKUP_DIR/backup-info.txt" <<INFO
Backup Type: $BACKUP_TYPE
Date: $(date)
WordPress Version: $(wp core version --path=/var/www/html/wordpress 2>/dev/null || echo "Unknown")
Database: $DB_NAME
Files Size: $(du -sh /var/www/html/wordpress | cut -f1)
INFO

# Calculate total size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log_message "✅ Backup completed! Total size: $TOTAL_SIZE"

# Retention policy
cleanup_old_backups() {
    local type=$1
    local keep=$2
    
    if [ "$type" = "daily" ]; then
        find "$BACKUP_ROOT/daily" -type d -mtime +$keep -exec rm -rf {} \; 2>/dev/null
        log_message "Cleaned up daily backups older than $keep days"
    elif [ "$type" = "weekly" ]; then
        find "$BACKUP_ROOT/weekly" -type d -mtime +$keep -exec rm -rf {} \; 2>/dev/null
        log_message "Cleaned up weekly backups older than $keep days"
    fi
}

# Apply retention based on backup type
case $BACKUP_TYPE in
    daily)
        cleanup_old_backups "daily" 7
        ;;
    weekly)
        cleanup_old_backups "weekly" 30
        ;;
    monthly)
        find "$BACKUP_ROOT/monthly" -type d -mtime +365 -exec rm -rf {} \; 2>/dev/null
        ;;
esac

# Optional: Sync to remote storage (if configured)
if [ -f "/root/.config/rclone/rclone.conf" ] && [ -n "$(rclone listremotes 2>/dev/null)" ]; then
    log_message "Syncing to remote storage..."
    rclone sync "$BACKUP_DIR" "easyinstall-backups:$BACKUP_TYPE/$DATE" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        log_message "✅ Remote sync completed"
    else
        log_message "❌ Remote sync failed"
    fi
fi

log_message "All tasks completed!"
echo ""
echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "Location: $BACKUP_DIR"
echo -e "Size: $TOTAL_SIZE"
echo -e "Log: $LOG_FILE"
EOF

    chmod +x /usr/local/bin/easy-backup
    
    # Create backup restore script
    cat > /usr/local/bin/easy-restore <<'EOF'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🔄 WordPress Restore Utility${NC}"
echo ""

# List available backups
echo "Available backups:"
echo "1) Daily backups"
echo "2) Weekly backups"
echo "3) Monthly backups"
echo "4) Specific path"
read -p "Select option (1-4): " BACKUP_SOURCE

case $BACKUP_SOURCE in
    1) BACKUP_PATH="/backups/daily" ;;
    2) BACKUP_PATH="/backups/weekly" ;;
    3) BACKUP_PATH="/backups/monthly" ;;
    4) read -p "Enter full backup path: " BACKUP_PATH ;;
    *) echo -e "${RED}Invalid option${NC}"; exit 1 ;;
esac

if [ ! -d "$BACKUP_PATH" ]; then
    echo -e "${RED}Backup directory not found${NC}"
    exit 1
fi

# List available backups
echo ""
echo "Available backups in $BACKUP_PATH:"
ls -lh "$BACKUP_PATH" | grep ^d | awk '{print NR") " $9 " (" $3")"}'
read -p "Select backup number: " BACKUP_NUM

SELECTED_BACKUP=$(ls -d "$BACKUP_PATH"/*/ | sed -n "${BACKUP_NUM}p")
if [ -z "$SELECTED_BACKUP" ]; then
    echo -e "${RED}Invalid selection${NC}"
    exit 1
fi

echo -e "${YELLOW}Selected backup: $SELECTED_BACKUP${NC}"
echo -e "${RED}Warning: This will overwrite current WordPress installation${NC}"
read -p "Continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Stop services
echo "Stopping services..."
systemctl stop nginx php*-fpm

# Restore database
if [ -f "$SELECTED_BACKUP/database.sql.gz" ]; then
    echo "Restoring database..."
    gunzip -c "$SELECTED_BACKUP/database.sql.gz" | mysql
    echo -e "${GREEN}✅ Database restored${NC}"
fi

# Restore files
if [ -f "$SELECTED_BACKUP/wordpress-files.tar.gz" ]; then
    echo "Restoring WordPress files..."
    rm -rf /var/www/html/wordpress
    tar -xzf "$SELECTED_BACKUP/wordpress-files.tar.gz" -C /var/www/html
    chown -R www-data:www-data /var/www/html/wordpress
    echo -e "${GREEN}✅ Files restored${NC}"
fi

# Restore Nginx config
if [ -f "$SELECTED_BACKUP/nginx-config.tar.gz" ]; then
    echo "Restoring Nginx configuration..."
    tar -xzf "$SELECTED_BACKUP/nginx-config.tar.gz" -C /etc
    echo -e "${GREEN}✅ Nginx config restored${NC}"
fi

# Start services
echo "Starting services..."
systemctl start nginx php*-fpm

echo -e "${GREEN}✅ Restore completed successfully!${NC}"
EOF

    chmod +x /usr/local/bin/easy-restore
    
    # Setup automated backups via cron
    cat > /etc/cron.d/easyinstall-backups <<EOF
# Daily backup at 2 AM
0 2 * * * root /usr/local/bin/easy-backup daily > /dev/null 2>&1

# Weekly backup on Sunday at 3 AM
0 3 * * 0 root /usr/local/bin/easy-backup weekly > /dev/null 2>&1

# Monthly backup on 1st at 4 AM
0 4 1 * * root /usr/local/bin/easy-backup monthly > /dev/null 2>&1
EOF

    # Configure automysqlbackup
    sed -i 's/^CONFIG_mysql_dump_max_size=.*/CONFIG_mysql_dump_max_size=1024/' /etc/default/automysqlbackup
    
    echo -e "${GREEN}   ✅ Backup system configured${NC}"
}

# ============================================
# Monitoring System Setup
# ============================================
setup_monitoring() {
    echo -e "${YELLOW}📊 Setting up monitoring system...${NC}"
    
    # Configure Netdata
    cat > /etc/netdata/netdata.conf <<EOF
[global]
    run as user = netdata
    web files owner = root
    web files group = root
    update every = 2
    history = 3600
    memory mode = ram
    
[web]
    bind to = 127.0.0.1
    port = 19999
    mode = static-threaded
    
[plugin:proc]
    /proc/net/dev = yes
    /proc/diskstats = yes
    /proc/meminfo = yes
    /proc/stat = yes
    
[plugin:python]
    enabled = no
EOF

    # Restart netdata
    systemctl restart netdata
    
    # Create resource monitoring script
    cat > /usr/local/bin/check-resources <<'EOF'
#!/bin/bash

# Configuration
ADMIN_EMAIL="admin@$(hostname)"
ALERT_LOAD=2.0
ALERT_MEM=90
ALERT_DISK=85
LOG_FILE="/var/log/resource-alerts.log"

log_alert() {
    echo "[$(date)] $1" >> "$LOG_FILE"
    echo "$1" | mail -s "Server Alert: $(hostname)" "$ADMIN_EMAIL"
}

# Check load average
LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | sed 's/ //g')
if (( $(echo "$LOAD > $ALERT_LOAD" | bc -l) )); then
    log_alert "⚠️ High load average: $LOAD (threshold: $ALERT_LOAD)"
fi

# Check memory usage
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
if [ $MEM_PERCENT -gt $ALERT_MEM ]; then
    log_alert "⚠️ High memory usage: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
fi

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt $ALERT_DISK ]; then
    log_alert "⚠️ Low disk space: ${DISK_USAGE}% used"
    
    # Auto-clean if critical
    if [ $DISK_USAGE -gt 95 ]; then
        echo "Critical disk usage - cleaning old logs and cache..."
        
        # Clean old logs
        find /var/log -name "*.log" -mtime +30 -delete
        
        # Clean Nginx cache
        rm -rf /var/cache/nginx/*
        
        # Clean old backups
        find /backups/daily -type d -mtime +14 -exec rm -rf {} \; 2>/dev/null
        
        systemctl reload nginx
        log_alert "✅ Automatic cleanup performed"
    fi
fi

# Check Nginx status
if ! systemctl is-active --quiet nginx; then
    log_alert "❌ Nginx is not running!"
    systemctl restart nginx
    log_alert "✅ Nginx restarted automatically"
fi

# Check PHP-FPM status
if ! pgrep -f php-fpm > /dev/null; then
    log_alert "❌ PHP-FPM is not running!"
    systemctl restart php*-fpm
    log_alert "✅ PHP-FPM restarted automatically"
fi

# Check MariaDB status
if ! systemctl is-active --quiet mariadb; then
    log_alert "❌ MariaDB is not running!"
    systemctl restart mariadb
    log_alert "✅ MariaDB restarted automatically"
fi

# Check Redis status
if ! systemctl is-active --quiet redis-server; then
    log_alert "❌ Redis is not running!"
    systemctl restart redis-server
    log_alert "✅ Redis restarted automatically"
fi

# Check SSL certificates expiry
if command -v certbot &> /dev/null; then
    certbot certificates 2>/dev/null | grep -A2 "Certificate Name" | while read line; do
        if [[ $line == *"Expiry Date:"* ]]; then
            EXPIRY_DATE=$(echo $line | cut -d: -f2-)
            EXPIRY_SECONDS=$(date -d "$EXPIRY_DATE" +%s)
            NOW_SECONDS=$(date +%s)
            DAYS_LEFT=$(( ($EXPIRY_SECONDS - $NOW_SECONDS) / 86400 ))
            
            if [ $DAYS_LEFT -lt 7 ]; then
                log_alert "⚠️ SSL certificate expires in $DAYS_LEFT days"
            fi
        fi
    done
fi

# Check for failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
if [ $FAILED_LOGINS -gt 100 ]; then
    log_alert "⚠️ High number of failed login attempts: $FAILED_LOGINS"
fi
EOF

    chmod +x /usr/local/bin/check-resources
    
    # Add to crontab
    echo "*/15 * * * * root /usr/local/bin/check-resources > /dev/null 2>&1" >> /etc/crontab
    
    # Create performance report script
    cat > /usr/local/bin/easy-report <<'EOF'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 EasyInstall Performance Report${NC}"
echo "=================================="
echo ""

# System uptime
echo -e "${YELLOW}System Uptime:${NC}"
uptime
echo ""

# CPU info
echo -e "${YELLOW}CPU Usage:${NC}"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "   Usage: " 100 - $1"%"}'
echo "   Load average: $(cat /proc/loadavg | cut -d' ' -f1-3)"
echo ""

# Memory info
echo -e "${YELLOW}Memory Usage:${NC}"
free -h | awk 'NR==2{printf "   Total: %s, Used: %s, Free: %s\n", $2, $3, $4}'
free -h | awk 'NR==3{printf "   Swap:  %s, Used: %s, Free: %s\n", $2, $3, $4}'
echo ""

# Disk usage
echo -e "${YELLOW}Disk Usage:${NC}"
df -h / | awk 'NR==2{printf "   Total: %s, Used: %s (%s), Free: %s\n", $2, $3, $5, $4}'
echo ""

# Service status
echo -e "${YELLOW}Service Status:${NC}"
services=("nginx" "php*-fpm" "mariadb" "redis-server" "netdata" "fail2ban")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "   ✅ $service: $(systemctl status $service | grep "Active:" | cut -d: -f2- | cut -d' ' -f2- | head -1)"
    fi
done
echo ""

# Cache stats
echo -e "${YELLOW}Cache Statistics:${NC}"
if [ -d "/var/cache/nginx" ]; then
    echo "   Nginx Cache: $(du -sh /var/cache/nginx | cut -f1)"
fi
if command -v redis-cli &> /dev/null; then
    REDIS_MEM=$(redis-cli info memory | grep used_memory_human | cut -d: -f2)
    echo "   Redis Memory: $REDIS_MEM"
fi
echo ""

# Database stats
echo -e "${YELLOW}Database Statistics:${NC}"
if [ -f "/var/www/html/wordpress/wp-config.php" ]; then
    DB_NAME=$(grep DB_NAME /var/www/html/wordpress/wp-config.php | cut -d"'" -f4)
    DB_SIZE=$(mysql -e "SELECT ROUND(SUM(data_length+index_length)/1024/1024,2) FROM information_schema.tables WHERE table_schema='$DB_NAME'" 2>/dev/null | tail -1)
    echo "   Database Size: ${DB_SIZE}MB"
    echo "   Table Count: $(mysql -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME'" 2>/dev/null | tail -1)"
fi
echo ""

# Backup stats
echo -e "${YELLOW}Backup Information:${NC}"
if [ -d "/backups" ]; then
    LATEST_BACKUP=$(ls -td /backups/daily/* 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        BACKUP_DATE=$(basename "$LATEST_BACKUP")
        BACKUP_SIZE=$(du -sh "$LATEST_BACKUP" | cut -f1)
        echo "   Latest Backup: $BACKUP_DATE"
        echo "   Backup Size: $BACKUP_SIZE"
    fi
fi
echo ""

# Security stats
echo -e "${YELLOW}Security Information:${NC}"
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
echo "   Failed SSH attempts: $FAILED_LOGINS"
echo "   Fail2ban jails: $(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2)"
echo ""

echo -e "${GREEN}Report generated: $(date)${NC}"
EOF

    chmod +x /usr/local/bin/easy-report
    
    echo -e "${GREEN}   ✅ Monitoring system configured${NC}"
}

# ============================================
# CDN Integration Setup
# ============================================
setup_cdn() {
    echo -e "${YELLOW}☁️  Setting up CDN integration...${NC}"
    
    # Create CDN configuration script
    cat > /usr/local/bin/easy-cdn <<'EOF'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

configure_cloudflare() {
    local DOMAIN=$1
    local API_KEY=$2
    local EMAIL=$3
    
    echo -e "${YELLOW}Configuring Cloudflare for $DOMAIN...${NC}"
    
    # Get zone ID
    ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
        -H "X-Auth-Email: $EMAIL" \
        -H "X-Auth-Key: $API_KEY" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')
    
    if [ "$ZONE_ID" = "null" ]; then
        echo -e "${RED}Failed to get zone ID. Check domain and API key.${NC}"
        return 1
    fi
    
    # Update WordPress with Cloudflare plugin
    if command -v wp &> /dev/null; then
        cd /var/www/html/wordpress
        wp plugin install cloudflare --activate
        wp option update cloudflare_api_key "$API_KEY"
        wp option update cloudflare_email "$EMAIL"
        wp option update cloudflare_zone_id "$ZONE_ID"
        echo -e "${GREEN}✅ Cloudflare plugin configured${NC}"
    fi
    
    # Add Cloudflare IPs to Nginx
    cat > /etc/nginx/cloudflare.conf <<CFCONF
# Cloudflare IPs
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 104.16.0.0/13;
set_real_ip_from 104.24.0.0/14;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 131.0.72.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
real_ip_header CF-Connecting-IP;
CFCONF
    
    # Include in Nginx config
    if ! grep -q "cloudflare.conf" /etc/nginx/sites-available/wordpress; then
        sed -i '/server_name/a \    include /etc/nginx/cloudflare.conf;' /etc/nginx/sites-available/wordpress
        nginx -t && systemctl reload nginx
    fi
    
    echo -e "${GREEN}✅ Cloudflare configuration completed${NC}"
}

configure_bunnycdn() {
    local DOMAIN=$1
    local API_KEY=$2
    local STORAGE_ZONE=$3
    
    echo -e "${YELLOW}Configuring BunnyCDN for $DOMAIN...${NC}"
    
    # Create CDN rewrite rules
    cat > /etc/nginx/bunnycdn.conf <<BUNNYCONF
# BunnyCDN Configuration
location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg|eot)$ {
    expires 365d;
    add_header Cache-Control "public, immutable";
    add_header CDN-Provider "BunnyCDN";
    
    # Optional: Rewrite to BunnyCDN
    # rewrite ^(.*)$ https://${STORAGE_ZONE}.b-cdn.net\$1 permanent;
}
BUNNYCONF
    
    # Include in Nginx config
    if ! grep -q "bunnycdn.conf" /etc/nginx/sites-available/wordpress; then
        sed -i '/location ~* \.(jpg|jpeg|png|gif|ico|css|js)/, /}/ d' /etc/nginx/sites-available/wordpress
        echo "include /etc/nginx/bunnycdn.conf;" >> /etc/nginx/sites-available/wordpress
        nginx -t && systemctl reload nginx
    fi
    
    # Install CDN enabler plugin
    if command -v wp &> /dev/null; then
        cd /var/www/html/wordpress
        wp plugin install cdn-enabler --activate
        wp option update cdn_enabler_url "https://${STORAGE_ZONE}.b-cdn.net"
        echo -e "${GREEN}✅ BunnyCDN plugin configured${NC}"
    fi
}

configure_quickcache() {
    echo -e "${YELLOW}Configuring QuickCache...${NC}"
    
    if command -v wp &> /dev/null; then
        cd /var/www/html/wordpress
        wp plugin install quick-cache --activate
        
        # Configure QuickCache
        wp option update quick_cache_options '{
            "enable": "1",
            "cache_expiration_time": "3600",
            "cache_cleanup_interval": "86400",
            "cache_max_size": "100",
            "enable_gzip": "1",
            "excluded_uris": "",
            "excluded_agents": ""
        }' --format=json
        
        echo -e "${GREEN}✅ QuickCache configured${NC}"
    fi
}

# Main CDN command handler
case "$1" in
    cloudflare)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "Usage: easy-cdn cloudflare domain.com api-key email@example.com"
            exit 1
        fi
        configure_cloudflare "$2" "$3" "$4"
        ;;
    bunnycdn)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "Usage: easy-cdn bunnycdn domain.com api-key storage-zone"
            exit 1
        fi
        configure_bunnycdn "$2" "$3" "$4"
        ;;
    quickcache)
        configure_quickcache
        ;;
    *)
        echo -e "${YELLOW}EasyInstall CDN Manager${NC}"
        echo ""
        echo "Usage: easy-cdn [command]"
        echo ""
        echo "Commands:"
        echo "  cloudflare domain.com api-key email    - Configure Cloudflare"
        echo "  bunnycdn domain.com api-key zone       - Configure BunnyCDN"
        echo "  quickcache                              - Configure QuickCache"
        ;;
esac
EOF

    chmod +x /usr/local/bin/easy-cdn
    
    # Install jq for JSON parsing
    apt install -y jq
    
    echo -e "${GREEN}   ✅ CDN integration tools installed${NC}"
}

# ============================================
# Email Service Setup
# ============================================
setup_email() {
    echo -e "${YELLOW}📧 Setting up email service...${NC}"
    
    # Install postfix and dependencies
    debconf-set-selections <<< "postfix postfix/mailname string $(hostname -f)"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    apt install -y postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql
    
    # Configure Postfix for local delivery only (to save memory)
    cat > /etc/postfix/main.cf <<EOF
# Basic configuration
myhostname = $(hostname -f)
mydomain = $(hostname -d)
myorigin = \$mydomain
inet_interfaces = localhost
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128

# Restrictions
smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination

# Performance
default_process_limit = 50
smtpd_client_connection_rate_limit = 10
queue_minfree = 50M
bounce_queue_lifetime = 1d
maximal_queue_lifetime = 1d
EOF

    # Create transactional email script
    cat > /usr/local/bin/easy-mail <<'EOF'
#!/bin/bash

send_transactional() {
    local TO=$1
    local SUBJECT=$2
    local BODY=$3
    
    echo "$BODY" | mail -s "$SUBJECT" -a "From: WordPress <noreply@$(hostname)>" "$TO"
}

send_alert() {
    local MESSAGE=$1
    local LOG_FILE="/var/log/mail-alerts.log"
    
    echo "[$(date)] $MESSAGE" >> "$LOG_FILE"
    
    # Send to admin
    if [ -f "/root/.admin_email" ]; then
        ADMIN_EMAIL=$(cat /root/.admin_email)
        echo "$MESSAGE" | mail -s "Alert: $(hostname)" "$ADMIN_EMAIL"
    fi
}

case "$1" in
    send)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "Usage: easy-mail send to@email.com subject body"
            exit 1
        fi
        send_transactional "$2" "$3" "$4"
        ;;
    alert)
        send_alert "$2"
        ;;
    config)
        if [ -n "$2" ]; then
            echo "$2" > /root/.admin_email
            echo "Admin email set to: $2"
        else
            echo "Current admin email: $(cat /root/.admin_email 2>/dev/null || echo 'Not set')"
        fi
        ;;
    *)
        echo "EasyInstall Email Utility"
        echo ""
        echo "Commands:"
        echo "  send to@email.com subject body  - Send email"
        echo "  alert message                    - Send alert"
        echo "  config email@example.com         - Set admin email"
        ;;
esac
EOF

    chmod +x /usr/local/bin/easy-mail
    
    # Create admin email file
    echo "admin@$(hostname)" > /root/.admin_email
    
    # Configure WordPress to use local mail
    if [ -f "/var/www/html/wordpress/wp-config.php" ]; then
        cat >> /var/www/html/wordpress/wp-config.php <<EOF

/** Mail Configuration */
define('SMTP_HOST', 'localhost');
define('SMTP_PORT', 25);
define('SMTP_AUTH', false);
EOF
    fi
    
    systemctl restart postfix
    
    echo -e "${GREEN}   ✅ Email service configured (local delivery only)${NC}"
}

# ============================================
# Multi-site Panel Support
# ============================================
setup_panel() {
    echo -e "${YELLOW}🏢 Setting up multi-site panel support...${NC}"
    
    mkdir -p /var/www/sites
    
    # Create site management script
    cat > /usr/local/bin/easy-site <<'EOF'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SITES_DIR="/var/www/sites"
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"

create_site() {
    local DOMAIN=$1
    local SITE_DIR="$SITES_DIR/$DOMAIN"
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}Error: Domain name required${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Creating site for $DOMAIN...${NC}"
    
    # Create site directory
    mkdir -p "$SITE_DIR/public"
    mkdir -p "$SITE_DIR/logs"
    mkdir -p "$SITE_DIR/backups"
    
    # Download WordPress
    cd "$SITE_DIR/public"
    wp core download --allow-root
    
    # Create wp-config
    DB_NAME="site_$(echo $DOMAIN | sed 's/\./_/g')"
    DB_USER="user_$(openssl rand -hex 4)"
    DB_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c20)
    
    mysql -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    
    wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --allow-root
    
    # Get PHP version
    PHP_VERSION=$(ls /etc/php/ | head -1)
    
    # Create Nginx config
    cat > "$NGINX_AVAILABLE/$DOMAIN" <<NGINXEOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $DOMAIN www.$DOMAIN;
    
    root $SITE_DIR/public;
    index index.php index.html index.htm;
    
    access_log $SITE_DIR/logs/access.log;
    error_log $SITE_DIR/logs/error.log;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
    }
    
    location ~ /\. {
        deny all;
    }
}
NGINXEOF
    
    # Enable site
    ln -sf "$NGINX_AVAILABLE/$DOMAIN" "$NGINX_ENABLED/"
    
    # Set permissions
    chown -R www-data:www-data "$SITE_DIR"
    
    # Reload Nginx
    nginx -t && systemctl reload nginx
    
    # Save site info
    cat > "$SITE_DIR/site-info.txt" <<INFO
Domain: $DOMAIN
Path: $SITE_DIR
Database: $DB_NAME
DB User: $DB_USER
DB Pass: $DB_PASS
Created: $(date)
INFO
    
    echo -e "${GREEN}✅ Site created successfully!${NC}"
    echo ""
    echo "Site URL: http://$DOMAIN"
    echo "Database: $DB_NAME"
    echo "DB User: $DB_USER"
    echo "DB Pass: $DB_PASS"
    echo ""
    echo "Complete WordPress installation at: http://$DOMAIN/wp-admin/install.php"
}

delete_site() {
    local DOMAIN=$1
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}Error: Domain name required${NC}"
        return 1
    fi
    
    echo -e "${RED}⚠️  Warning: This will delete all data for $DOMAIN${NC}"
    read -p "Continue? (y/n): " CONFIRM
    
    if [ "$CONFIRM" != "y" ]; then
        echo "Operation cancelled"
        return 0
    fi
    
    # Get database info
    if [ -f "$SITES_DIR/$DOMAIN/site-info.txt" ]; then
        DB_NAME=$(grep Database "$SITES_DIR/$DOMAIN/site-info.txt" | cut -d: -f2 | sed 's/ //g')
        DB_USER=$(grep "DB User" "$SITES_DIR/$DOMAIN/site-info.txt" | cut -d: -f2 | sed 's/ //g')
        
        # Drop database
        mysql -e "DROP DATABASE IF EXISTS $DB_NAME;"
        mysql -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
    fi
    
    # Remove Nginx config
    rm -f "$NGINX_AVAILABLE/$DOMAIN"
    rm -f "$NGINX_ENABLED/$DOMAIN"
    
    # Remove site directory
    rm -rf "$SITES_DIR/$DOMAIN"
    
    # Reload Nginx
    nginx -t && systemctl reload nginx
    
    echo -e "${GREEN}✅ Site deleted successfully${NC}"
}

list_sites() {
    echo -e "${YELLOW}📋 WordPress Sites:${NC}"
    echo ""
    
    if [ ! -d "$SITES_DIR" ] || [ -z "$(ls -A "$SITES_DIR")" ]; then
        echo "No sites found"
        return 0
    fi
    
    for site in "$SITES_DIR"/*; do
        if [ -d "$site" ]; then
            DOMAIN=$(basename "$site")
            if [ -f "$site/site-info.txt" ]; then
                DB_NAME=$(grep Database "$site/site-info.txt" | cut -d: -f2)
                echo "  🌐 $DOMAIN"
                echo "     📁 Path: $site"
                echo "     🗄️  DB: $DB_NAME"
                echo ""
            fi
        fi
    done
}

case "$1" in
    create)
        create_site "$2"
        ;;
    delete)
        delete_site "$2"
        ;;
    list)
        list_sites
        ;;
    *)
        echo -e "${YELLOW}EasyInstall Site Manager${NC}"
        echo ""
        echo "Usage: easy-site [command]"
        echo ""
        echo "Commands:"
        echo "  create domain.com    - Create new WordPress site"
        echo "  delete domain.com    - Delete site"
        echo "  list                 - List all sites"
        ;;
esac
EOF

    chmod +x /usr/local/bin/easy-site
    
    echo -e "${GREEN}   ✅ Multi-site panel configured${NC}"
    echo -e "   📌 Use 'easy-site create domain.com' to add new sites"
}

# ============================================
# Install Management Commands (Enhanced with new features)
# ============================================
install_commands() {
    echo -e "${YELLOW}🔧 Installing management commands...${NC}"
    
    # Create commands directory
    mkdir -p /usr/local/bin
    
    # Main easyinstall command with enhanced features
    cat > /usr/local/bin/easyinstall <<'EOF'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to get PHP version
get_php_version() {
    if command -v php >/dev/null 2>&1; then
        php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;'
    else
        echo "8.2"  # Default
    fi
}

# Function to install WordPress plugins (Fixed permissions)
install_wp_plugins() {
    local DOMAIN=$1
    
    echo -e "${YELLOW}🔌 Installing WordPress plugins...${NC}"
    
    # Check if wp-cli is installed
    if ! command -v wp &> /dev/null; then
        echo -e "${YELLOW}📦 Installing WP-CLI...${NC}"
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    fi
    
    cd /var/www/html/wordpress
    
    # Ensure proper permissions
    chown -R www-data:www-data /var/www/html/wordpress
    chmod -R 775 /var/www/html/wordpress/wp-content
    
    # Install and configure Nginx Helper plugin
    echo -e "   📥 Installing Nginx Helper plugin..."
    sudo -u www-data wp plugin install nginx-helper --activate
    
    # Configure Nginx Helper
    sudo -u www-data wp option update nginx_helper_options '{
        "enable_purge": "1",
        "cache_method": "enable_fastcgi",
        "purge_method": "get_request",
        "redis_hostname": "127.0.0.1",
        "redis_port": "6379"
    }' --format=json
    
    # Install and configure Redis Object Cache plugin
    echo -e "   📥 Installing Redis Object Cache plugin..."
    sudo -u www-data wp plugin install redis-cache --activate
    
    # Enable Redis cache
    sudo -u www-data wp redis enable
    
    echo -e "${GREEN}   ✅ WordPress plugins installed and configured${NC}"
}

# Function to install SSL certificate
install_ssl() {
    local DOMAIN=$1
    local EMAIL=$2
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}❌ Error: Domain name required${NC}"
        echo -e "${YELLOW}Usage: easyinstall ssl example.com [email]${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔐 Installing SSL certificate for $DOMAIN...${NC}"
    
    # Remove http:// or https:// if present
    DOMAIN=$(echo $DOMAIN | sed 's~http[s]*://~~g' | sed 's~/.*~~')
    
    # Check if domain points to this server
    if command -v dig &> /dev/null; then
        DOMAIN_IP=$(dig +short $DOMAIN | head -1)
        if [ -z "$DOMAIN_IP" ]; then
            DOMAIN_IP=$(host $DOMAIN | grep "has address" | head -1 | awk '{print $NF}')
        fi
        SERVER_IP=$(curl -s ifconfig.me)
        
        if [ -n "$DOMAIN_IP" ] && [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
            echo -e "${RED}⚠️  Warning: $DOMAIN points to $DOMAIN_IP, not this server ($SERVER_IP)${NC}"
            echo -e "${YELLOW}SSL may fail. Continue anyway? (y/n)${NC}"
            read -r answer
            if [ "$answer" != "y" ]; then
                echo -e "${RED}❌ SSL installation cancelled${NC}"
                return 1
            fi
        fi
    fi
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}📦 Installing Certbot...${NC}"
        apt update
        apt install -y certbot python3-certbot-nginx
    fi
    
    # Set email
    if [ -z "$EMAIL" ]; then
        EMAIL="admin@$DOMAIN"
    fi
    
    # Update Nginx server_name if still underscore
    if grep -q "server_name _;" /etc/nginx/sites-available/wordpress; then
        echo -e "${YELLOW}📝 Updating Nginx server_name to $DOMAIN...${NC}"
        sed -i "s/server_name _;/server_name $DOMAIN;/" /etc/nginx/sites-available/wordpress
        nginx -t && systemctl reload nginx
    fi
    
    # Stop nginx temporarily for better SSL issuance
    systemctl stop nginx
    
    # Install SSL certificate
    echo -e "${YELLOW}⚡ Obtaining SSL certificate from Let's Encrypt...${NC}"
    certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email $EMAIL
    
    CERT_RESULT=$?
    
    # Start nginx again
    systemctl start nginx
    
    if [ $CERT_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
        
        # Get PHP version
        PHP_VERSION=$(get_php_version)
        
        # Update Nginx config to use SSL
        cat > /etc/nginx/sites-available/wordpress <<NGINXEOF
# FastCGI Cache Zone
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;
fastcgi_cache_key "\$scheme\$request_method\$host\$request_uri";
fastcgi_cache_use_stale error timeout updating invalid_header http_500 http_503;
fastcgi_cache_lock on;
fastcgi_cache_valid 200 301 302 60m;
fastcgi_cache_valid 404 1m;
fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name $DOMAIN;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    root /var/www/html/wordpress;
    index index.php index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Cache \$upstream_cache_status;
    
    # Logs
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;
    
    # Static files cache
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg|eot)$ {
        expires 365d;
        add_header Cache-Control "public, immutable";
    }
    
    # WordPress URLs
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP processing with FastCGI Cache
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        
        # FastCGI Cache
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_methods GET HEAD;
        add_header X-Cache \$upstream_cache_status;
        
        # Skip cache for cookies
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        
        # Define cache skip conditions
        set \$skip_cache 0;
        if (\$request_method = POST) {
            set \$skip_cache 1;
        }
        if (\$query_string != "") {
            set \$skip_cache 1;
        }
        if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
            set \$skip_cache 1;
        }
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to sensitive files
    location ~ ^/(wp-config\.php|wp-config\.txt|readme\.html|license\.txt|wp-config-sample\.php) {
        deny all;
    }
}
NGINXEOF

        nginx -t && systemctl reload nginx
        
        # Install WordPress plugins
        install_wp_plugins "$DOMAIN"
        
        # Update WordPress URLs to HTTPS
        if command -v wp &> /dev/null; then
            cd /var/www/html/wordpress
            sudo -u www-data wp option update home "https://$DOMAIN"
            sudo -u www-data wp option update siteurl "https://$DOMAIN"
            echo -e "${GREEN}   ✅ WordPress URLs updated to HTTPS${NC}"
        fi
        
        # Add SSL renewal cron job (twice daily)
        if ! grep -q "certbot renew" /etc/crontab; then
            echo "0 */12 * * * root certbot renew --quiet --post-hook 'systemctl reload nginx'" >> /etc/crontab
            echo -e "${GREEN}   ✅ SSL auto-renewal configured${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}📋 SSL Information:${NC}"
        echo "   • Domain: $DOMAIN"
        echo "   • Expiry: $(certbot certificates | grep -A2 $DOMAIN | grep Expiry | cut -d: -f2-)"
        echo "   • Path: /etc/letsencrypt/live/$DOMAIN/"
        echo ""
        echo -e "${GREEN}🔌 Plugins Installed:${NC}"
        echo "   • Nginx Helper - Configured for FastCGI cache"
        echo "   • Redis Object Cache - Enabled and connected"
        echo ""
        echo -e "${YELLOW}📌 Next Steps:${NC}"
        echo "   1. Complete WordPress installation at: https://$DOMAIN/wp-admin/install.php"
        echo "   2. Login to wp-admin and verify plugins are active"
        echo "   3. Check Redis cache status in WordPress > Tools > Redis"
        
    else
        echo -e "${RED}❌ SSL installation failed${NC}"
        echo -e "${YELLOW}Possible issues:${NC}"
        echo "   • Domain doesn't point to this server"
        echo "   • Port 80 is blocked by firewall"
        echo "   • Domain not propagated yet (wait 5-10 minutes)"
        echo "   • Rate limited by Let's Encrypt"
        echo ""
        echo -e "${YELLOW}Try manually:${NC}"
        echo "   certbot --nginx -d $DOMAIN"
        return 1
    fi
}

# Function to reinstall WordPress
reinstall_wordpress() {
    echo -e "${YELLOW}🔄 Reinstalling WordPress...${NC}"
    
    # Backup existing WordPress
    if [ -d "/var/www/html/wordpress" ]; then
        BACKUP_DIR="/root/wordpress-backup-$(date +%Y%m%d-%H%M%S)"
        echo -e "   📦 Creating backup at $BACKUP_DIR"
        cp -r /var/www/html/wordpress $BACKUP_DIR
        mysqldump --all-databases > "$BACKUP_DIR/databases.sql" 2>/dev/null || true
    fi
    
    # Remove old WordPress
    rm -rf /var/www/html/wordpress
    
    # Download fresh WordPress
    cd /var/www/html
    curl -O https://wordpress.org/latest.zip
    unzip -o latest.zip
    rm -f latest.zip
    
    # Create necessary directories
    mkdir -p wordpress/wp-content/upgrade
    mkdir -p wordpress/wp-content/plugins
    mkdir -p wordpress/wp-content/themes
    mkdir -p wordpress/wp-content/uploads
    mkdir -p wordpress/wp-content/cache
    
    # Set permissions
    chown -R www-data:www-data wordpress
    chmod -R 755 wordpress
    chmod -R 775 wordpress/wp-content
    
    echo -e "${GREEN}✅ WordPress reinstalled successfully${NC}"
    echo -e "${YELLOW}📌 Note: Database was not modified. Backup saved at $BACKUP_DIR${NC}"
}

# Enhanced update function
update_domain() {
    local DOMAIN=$1
    local PHP_V=$2
    local REINSTALL=$3
    local CACHE=$4
    local SSL=$5
    local CLEARCACHE=$6
    
    echo -e "${YELLOW}🌐 Updating domain configuration for $DOMAIN...${NC}"
    
    # Update PHP version if specified
    if [ -n "$PHP_V" ] && [ "$PHP_V" != "false" ]; then
        echo -e "   📌 Switching to PHP $PHP_V..."
        
        # Install PHP version if not exists
        if ! dpkg -l | grep -q "php$PHP_V-fpm"; then
            apt update
            apt install -y php$PHP_V-fpm php$PHP_V-mysql php$PHP_V-cli \
                php$PHP_V-curl php$PHP_V-xml php$PHP_V-mbstring php$PHP_V-zip \
                php$PHP_V-gd php$PHP_V-imagick php$PHP_V-opcache php$PHP_V-redis \
                php$PHP_V-intl
        fi
        
        # Update Nginx config to use new PHP version
        sed -i "s|unix:/run/php/php[0-9]\.[0-9]-fpm.sock|unix:/run/php/php$PHP_V-fpm.sock|g" /etc/nginx/sites-available/wordpress
        
        # Disable old PHP-FPM and enable new
        systemctl stop php*-fpm 2>/dev/null || true
        systemctl start php$PHP_V-fpm
        systemctl enable php$PHP_V-fpm
        
        echo -e "${GREEN}   ✅ PHP version updated to $PHP_V${NC}"
    fi
    
    # Reinstall WordPress if requested
    if [ "$REINSTALL" = "true" ]; then
        reinstall_wordpress
    fi
    
    # Clear cache if requested
    if [ "$CLEARCACHE" = "true" ]; then
        echo -e "   🧹 Clearing FastCGI cache..."
        rm -rf /var/cache/nginx/*
        systemctl reload nginx
        echo -e "${GREEN}   ✅ Cache cleared${NC}"
    fi
    
    # Update Nginx server_name
    sed -i "s/server_name [^;]*;/server_name $DOMAIN;/g" /etc/nginx/sites-available/wordpress
    nginx -t && systemctl reload nginx
    
    # Update WordPress URLs if wp-cli exists
    if command -v wp &> /dev/null; then
        cd /var/www/html/wordpress
        PROTOCOL="http"
        if [ "$SSL" = "true" ]; then
            PROTOCOL="https"
        fi
        sudo -u www-data wp option update home "$PROTOCOL://$DOMAIN"
        sudo -u www-data wp option update siteurl "$PROTOCOL://$DOMAIN"
        echo -e "${GREEN}   ✅ WordPress URLs updated to $PROTOCOL://$DOMAIN${NC}"
    fi
    
    # Enable cache if requested
    if [ "$CACHE" = "true" ]; then
        if ! grep -q "WP_CACHE" /var/www/html/wordpress/wp-config.php; then
            echo "define('WP_CACHE', true);" >> /var/www/html/wordpress/wp-config.php
            echo -e "${GREEN}   ✅ Cache enabled in WordPress${NC}"
        fi
    fi
    
    # Install SSL if requested
    if [ "$SSL" = "true" ]; then
        install_ssl "$DOMAIN"
    fi
    
    echo -e "${GREEN}✅ Domain configuration updated successfully for $DOMAIN${NC}"
}

# Function to get PHP-FPM service
get_php_fpm_service() {
    if command -v php >/dev/null 2>&1; then
        PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
        echo "php$PHP_VER-fpm"
    else
        # Try to detect from systemd
        systemctl list-units --type=service --all 2>/dev/null | grep -o "php[0-9]\.[0-9]*-fpm\.service" | head -1 | sed 's/\.service//' || echo "php8.2-fpm"
    fi
}

# Parse update command options
parse_update_options() {
    local DOMAIN=""
    local PHP_V="false"
    local REINSTALL="false"
    local CACHE="false"
    local SSL="false"
    local CLEARCACHE="false"
    
    # First argument is always the domain
    DOMAIN="$2"
    
    # Parse remaining arguments
    shift 2
    for arg in "$@"; do
        case $arg in
            -php*v=*)
                PHP_V="${arg#*=}"
                ;;
            -reinstall)
                REINSTALL="true"
                ;;
            -cache=*)
                CACHE="${arg#*=}"
                ;;
            -ssl=*)
                SSL="${arg#*=}"
                ;;
            -clearcache)
                CLEARCACHE="true"
                ;;
        esac
    done
    
    update_domain "$DOMAIN" "$PHP_V" "$REINSTALL" "$CACHE" "$SSL" "$CLEARCACHE"
}

# Main command handler
case "$1" in
    domain)
        if [ -z "$2" ]; then
            echo -e "${RED}Usage: easyinstall domain yourdomain.com${NC}"
            exit 1
        fi
        
        # Check for advanced options
        if [ $# -gt 2 ]; then
            parse_update_options "$@"
        else
            # Simple domain update
            echo -e "${YELLOW}🌐 Changing domain to $2...${NC}"
            
            # Update Nginx config
            sed -i "s/server_name _;/server_name $2;/" /etc/nginx/sites-available/wordpress
            nginx -t && systemctl reload nginx
            
            # Update WordPress URLs if wp-cli exists
            if command -v wp &> /dev/null; then
                cd /var/www/html/wordpress
                sudo -u www-data wp option update home "http://$2"
                sudo -u www-data wp option update siteurl "http://$2"
            fi
            
            echo -e "${GREEN}✅ Domain updated to $2${NC}"
            echo -e "${YELLOW}💡 Next: Run 'easyinstall ssl $2' to add SSL and plugins${NC}"
        fi
        ;;
        
    ssl)
        if [ -z "$2" ]; then
            echo -e "${RED}Usage: easyinstall ssl yourdomain.com [email]${NC}"
            echo -e "${YELLOW}Example: easyinstall ssl example.com admin@example.com${NC}"
            exit 1
        fi
        install_ssl "$2" "$3"
        ;;
        
    migrate)
        if [ -z "$2" ]; then
            echo -e "${RED}Usage: easyinstall migrate yourdomain.com${NC}"
            exit 1
        fi
        echo -e "${YELLOW}🔄 Migrating from IP to $2...${NC}"
        
        # Update Nginx
        sed -i "s/server_name _;/server_name $2;/" /etc/nginx/sites-available/wordpress
        
        # Add HTTPS redirect
        sed -i '/listen 80;/a \    return 301 https://$server_name$request_uri;' /etc/nginx/sites-available/wordpress
        
        nginx -t && systemctl reload nginx
        
        echo -e "${GREEN}✅ Migration complete for $2${NC}"
        echo -e "${YELLOW}💡 Next: Run 'easyinstall ssl $2' to add SSL and plugins${NC}"
        ;;
        
    panel)
        if [ "$2" = "enable" ]; then
            echo -e "${YELLOW}🏢 Enabling multi-site panel mode...${NC}"
            mkdir -p /var/www/sites
            chown www-data:www-data /var/www/sites
            echo -e "${GREEN}✅ Panel mode enabled - sites directory created at /var/www/sites${NC}"
        else
            echo -e "${RED}Usage: easyinstall panel enable${NC}"
        fi
        ;;
        
    cache)
        if [ "$2" = "clear" ]; then
            echo -e "${YELLOW}🧹 Clearing FastCGI cache...${NC}"
            rm -rf /var/cache/nginx/*
            systemctl reload nginx
            echo -e "${GREEN}✅ Cache cleared${NC}"
        fi
        ;;
        
    redis)
        if [ "$2" = "enable" ]; then
            echo -e "${YELLOW}📦 Enabling Redis object cache...${NC}"
            if [ -f /var/www/html/wordpress/wp-config.php ]; then
                # Check if WP_CACHE is already defined
                if grep -q "WP_CACHE" /var/www/html/wordpress/wp-config.php; then
                    sed -i "s/define('WP_CACHE', false);/define('WP_CACHE', true);/" /var/www/html/wordpress/wp-config.php
                else
                    echo "define('WP_CACHE', true);" >> /var/www/html/wordpress/wp-config.php
                fi
                echo -e "${GREEN}✅ Redis cache enabled in WordPress${NC}"
                
                # Install Redis plugin if wp-cli exists
                if command -v wp &> /dev/null; then
                    cd /var/www/html/wordpress
                    sudo -u www-data wp plugin install redis-cache --activate
                    sudo -u www-data wp redis enable
                    echo -e "${GREEN}   ✅ Redis plugin installed and activated${NC}"
                fi
            fi
        fi
        ;;
        
    backup)
        if [ -z "$2" ]; then
            /usr/local/bin/easy-backup daily
        else
            /usr/local/bin/easy-backup "$2"
        fi
        ;;
        
    restore)
        /usr/local/bin/easy-restore
        ;;
        
    report)
        /usr/local/bin/easy-report
        ;;
        
    cdn)
        shift
        /usr/local/bin/easy-cdn "$@"
        ;;
        
    mail)
        shift
        /usr/local/bin/easy-mail "$@"
        ;;
        
    site)
        shift
        /usr/local/bin/easy-site "$@"
        ;;
        
    reinstall)
        reinstall_wordpress
        ;;
        
    status)
        PHP_FPM_SERVICE=$(get_php_fpm_service)
        
        echo -e "${YELLOW}📊 System Status:${NC}"
        echo "   • Nginx: $(systemctl is-active nginx)"
        echo "   • PHP-FPM: $(systemctl is-active $PHP_FPM_SERVICE 2>/dev/null || echo "inactive")"
        echo "   • MariaDB: $(systemctl is-active mariadb)"
        echo "   • Redis: $(systemctl is-active redis-server)"
        echo "   • Fail2ban: $(systemctl is-active fail2ban)"
        echo "   • Netdata: $(systemctl is-active netdata)"
        echo "   • Postfix: $(systemctl is-active postfix)"
        echo ""
        echo "   • Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
        echo "   • Memory Usage: $(free -h | awk '/Mem:/ {print $3"/"$2}')"
        echo "   • Cache Size: $(du -sh /var/cache/nginx 2>/dev/null | cut -f1)"
        echo "   • Backup Size: $(du -sh /backups 2>/dev/null | cut -f1)"
        
        # Check SSL certificates
        if [ -d "/etc/letsencrypt/live" ]; then
            echo ""
            echo -e "${GREEN}🔐 SSL Certificates:${NC}"
            certbot certificates 2>/dev/null | grep -E "Certificate Name|Expiry Date" | sed 's/^/   /'
        fi
        
        # Check WordPress plugins
        if [ -f /var/www/html/wordpress/wp-config.php ] && command -v wp &> /dev/null; then
            echo ""
            echo -e "${GREEN}🔌 WordPress Plugins:${NC}"
            cd /var/www/html/wordpress
            sudo -u www-data wp plugin list --status=active --field=name 2>/dev/null | sed 's/^/   • /'
        fi
        ;;
        
    help)
        echo -e "${GREEN}EasyInstall Enterprise Stack v2.1 - Complete Production Ready${NC}"
        echo ""
        echo -e "${YELLOW}🌐 Domain & SSL:${NC}"
        echo "  easyinstall domain <domain> [options]          - Update domain"
        echo "    Options: -php*v=8.2, -reinstall, -cache=on/off, -ssl=on/off, -clearcache"
        echo "  easyinstall ssl <domain> [email]               - Install SSL + plugins"
        echo "  easyinstall migrate <domain>                   - Migrate from IP to domain"
        echo ""
        echo -e "${YELLOW}💾 Backup & Restore:${NC}"
        echo "  easyinstall backup [daily|weekly|monthly]      - Create backup"
        echo "  easyinstall restore                             - Restore from backup"
        echo ""
        echo -e "${YELLOW}📊 Monitoring:${NC}"
        echo "  easyinstall report                              - Generate performance report"
        echo "  easyinstall status                              - Show system status"
        echo ""
        echo -e "${YELLOW}☁️  CDN Integration:${NC}"
        echo "  easyinstall cdn cloudflare domain key email    - Setup Cloudflare"
        echo "  easyinstall cdn bunnycdn domain key zone       - Setup BunnyCDN"
        echo "  easyinstall cdn quickcache                      - Setup QuickCache"
        echo ""
        echo -e "${YELLOW}📧 Email:${NC}"
        echo "  easyinstall mail config email@example.com      - Set admin email"
        echo "  easyinstall mail send to@email.com subj body   - Send email"
        echo ""
        echo -e "${YELLOW}🏢 Multi-site:${NC}"
        echo "  easyinstall site create domain.com             - Create new WordPress site"
        echo "  easyinstall site delete domain.com             - Delete site"
        echo "  easyinstall site list                           - List all sites"
        echo ""
        echo -e "${YELLOW}⚡ Performance:${NC}"
        echo "  easyinstall cache clear                         - Clear FastCGI cache"
        echo "  easyinstall redis enable                        - Enable Redis cache"
        echo "  easyinstall reinstall                           - Reinstall WordPress"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  easyinstall domain example.com -php*v=8.2 -ssl=on -cache=on -clearcache"
        echo "  easyinstall backup weekly"
        echo "  easyinstall cdn cloudflare example.com your-api-key admin@example.com"
        echo "  easyinstall site create testsite.com"
        ;;
        
    *)
        echo -e "${GREEN}EasyInstall Enterprise Stack v2.1 - Production Ready${NC}"
        echo -e "Usage: ${YELLOW}easyinstall [command]${NC}"
        echo ""
        echo "Available commands:"
        echo "  domain, ssl, migrate, backup, restore, report, status"
        echo "  cdn, mail, site, cache, redis, reinstall, help"
        echo ""
        echo "Run 'easyinstall help' for detailed usage"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/easyinstall
    
    # Create cache clear cron
    echo "0 3 * * * root /usr/local/bin/easyinstall cache clear > /dev/null 2>&1" > /etc/cron.d/easyinstall-cache
    
    # Create aliases
    echo "alias asyinstall='easyinstall'" >> /root/.bashrc
    echo "alias easyintall='easyinstall'" >> /root/.bashrc
    echo "alias easinstall='easyinstall'" >> /root/.bashrc
    
    echo -e "${GREEN}   ✅ Management commands installed (Complete Production Version)${NC}"
}

# ============================================
# Final Setup
# ============================================
finalize() {
    echo -e "${YELLOW}🎯 Finalizing installation...${NC}"
    
    # Enable services at boot
    echo -e "${YELLOW}   📌 Enabling services...${NC}"
    
    # Enable standard services
    systemctl enable nginx >/dev/null 2>&1
    systemctl enable mariadb >/dev/null 2>&1
    systemctl enable redis-server >/dev/null 2>&1
    systemctl enable fail2ban >/dev/null 2>&1
    systemctl enable netdata >/dev/null 2>&1
    systemctl enable postfix >/dev/null 2>&1
    
    # Properly enable PHP-FPM
    echo -e "   🔍 Detecting PHP-FPM service..."
    
    # Get PHP version from installed packages
    if command -v php >/dev/null 2>&1; then
        PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
    fi
    
    if [ -n "$PHP_VERSION" ]; then
        PHP_FPM_SERVICE="php$PHP_VERSION-fpm"
        if systemctl list-units --type=service --all | grep -q "$PHP_FPM_SERVICE"; then
            systemctl enable $PHP_FPM_SERVICE >/dev/null 2>&1
            systemctl start $PHP_FPM_SERVICE >/dev/null 2>&1
            echo -e "${GREEN}   ✅ PHP-FPM enabled: $PHP_FPM_SERVICE${NC}"
        else
            # Try to find any PHP-FPM service
            for version in 8.3 8.2 8.1 8.0 7.4; do
                if systemctl list-units --type=service --all | grep -q "php$version-fpm"; then
                    systemctl enable php$version-fpm >/dev/null 2>&1
                    systemctl start php$version-fpm >/nc/null 2>&1
                    echo -e "${GREEN}   ✅ PHP-FPM enabled: php$version-fpm${NC}"
                    PHP_FPM_SERVICE="php$version-fpm"
                    PHP_VERSION="$version"
                    break
                fi
            done
        fi
    fi
    
    # Final permission check for WordPress
    if [ -d "/var/www/html/wordpress" ]; then
        chown -R www-data:www-data /var/www/html/wordpress
        chmod -R 755 /var/www/html/wordpress
        chmod -R 775 /var/www/html/wordpress/wp-content
    fi
    
    # Set admin email
    echo "admin@$IP_ADDRESS" > /root/.admin_email
    
    # Create info file
    cat > /root/easyinstall-info.txt <<EOF
========================================
EasyInstall Enterprise Stack v2.1
Complete Production Ready Version
Installation Date: $(date)
========================================

WORDPRESS SITE:
  URL: http://$IP_ADDRESS
  Path: /var/www/html/wordpress

DATABASE:
  Name: ${DB_NAME}
  User: ${DB_USER}
  Pass: ${DB_PASS}

SERVICES:
  • Nginx: http://$IP_ADDRESS
  • PHP-FPM: Version ${PHP_VERSION}
  • MariaDB: Port 3306
  • Redis: Port 6379
  • Netdata: http://$IP_ADDRESS:19999
  • Postfix: Local mail only

COMMANDS:
  # System Management
  easyinstall status                    - Check system status
  easyinstall report                     - Generate performance report
  
  # Domain & SSL
  easyinstall domain yourdomain.com      - Change domain
  easyinstall ssl yourdomain.com         - Install SSL + plugins
  easyinstall migrate yourdomain.com     - Migrate to domain
  
  # Backup
  easyinstall backup [daily|weekly|monthly] - Create backup
  easyinstall restore                     - Restore from backup
  
  # Multi-site
  easyinstall site create domain.com     - Create new WordPress site
  easyinstall site list                   - List all sites
  
  # CDN
  easyinstall cdn cloudflare domain key email - Setup Cloudflare
  easyinstall cdn quickcache                 - Enable QuickCache
  
  # Email
  easyinstall mail config email@example.com  - Set admin email
  
  # Performance
  easyinstall cache clear                 - Clear FastCGI cache
  easyinstall redis enable                 - Enable Redis cache
  easyinstall reinstall                    - Reinstall WordPress

FIREWALL:
  Allowed ports: 22, 80, 443

BACKUP LOCATIONS:
  • Daily: /backups/daily/
  • Weekly: /backups/weekly/
  • Monthly: /backups/monthly/

MONITORING:
  • Netdata: http://$IP_ADDRESS:19999
  • Resource checks: Every 15 minutes
  • Email alerts: Configure with 'easyinstall mail config'

MULTI-SITE:
  • Sites directory: /var/www/sites/
  • Command: easyinstall site create domain.com

========================================
EOF
    
    # Display completion message
    echo -e "${GREEN}"
    echo "============================================"
    echo "✅ Installation Complete!"
    echo "============================================"
    echo ""
    echo "🌐 WordPress: http://$IP_ADDRESS"
    echo "📊 Netdata: http://$IP_ADDRESS:19999"
    echo ""
    echo "📊 Database:"
    echo "   Name: ${DB_NAME}"
    echo "   User: ${DB_USER}"
    echo "   Pass: ${DB_PASS}"
    echo ""
    echo "⚡ FastCGI Cache: Active"
    echo "🛡️  Firewall: Active (ports 22,80,443)"
    echo "💾 Auto Backup: Daily at 2 AM"
    echo "📝 Info saved to: /root/easyinstall-info.txt"
    echo ""
    echo -e "${GREEN}✨ Production Features:${NC}"
    echo "   • PHP ${PHP_VERSION} with OPcache"
    echo "   • Automated backup system"
    echo "   • Resource monitoring & alerts"
    echo "   • Multi-site panel support"
    echo "   • CDN integration ready"
    echo "   • Email notifications"
    echo "   • Performance reporting"
    echo ""
    echo "🔧 Available commands:"
    echo "   easyinstall help                    - Show all commands"
    echo "   easyinstall status                   - Check status"
    echo "   easyinstall report                    - View performance report"
    echo "   easyinstall backup weekly             - Create weekly backup"
    echo "   easyinstall site create testsite.com  - Add new site"
    echo ""
    echo -e "${YELLOW}🚀 Advanced domain update:${NC}"
    echo "   easyinstall domain example.com -php*v=8.2 -ssl=on -cache=on -clearcache"
    echo ""
    echo "============================================"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}☕  Support This Project${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}If you find this script useful, consider buying${NC}"
    echo -e "${WHITE}me a coffee. Your support keeps this project alive!${NC}"
    echo ""
    echo -e "${GREEN}👉  Donate with PayPal:${NC}"
    echo -e "${BLUE}    https://paypal.me/sugandodrai${NC}"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${NC}"
}

# ============================================
# Main Execution
# ============================================
main() {
    setup_swap
    kernel_tuning
    install_packages
    setup_database
    optimize_php
    configure_nginx
    install_wordpress
    configure_redis
    setup_security
    setup_backups
    setup_monitoring
    setup_cdn
    setup_email
    setup_panel
    install_commands
    finalize
}

# Run main function
main
