#!/bin/bash

set -e

# ============================================
# EasyInstall Enterprise Stack v2.0
# Ultra-Optimized 512MB VPS → Enterprise Grade Hosting Engine
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 EasyInstall Enterprise Stack v2.0${NC}"
echo -e "${GREEN}📦 Ultra-Optimized WordPress Hosting Engine${NC}"
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

echo -e "${YELLOW}📊 System Information:${NC}"
echo "   • RAM: ${TOTAL_RAM}MB"
echo "   • CPU Cores: ${TOTAL_CORES}"
echo "   • IP Address: ${IP_ADDRESS}"
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
# Install Required Packages
# ============================================
install_packages() {
    echo -e "${YELLOW}📦 Installing enterprise stack...${NC}"
    
    apt update
    apt install -y nginx mariadb-server php-fpm php-mysql \
        php-cli php-curl php-xml php-mbstring php-zip \
        php-gd php-imagick php-opcache php-redis \
        redis-server ufw fail2ban curl wget unzip openssl \
        certbot python3-certbot-nginx \
        htop neofetch git cron
        
    echo -e "${GREEN}   ✅ All packages installed${NC}"
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
    
    echo -e "${GREEN}   ✅ Database configured${NC}"
}

# ============================================
# PHP-FPM Optimization
# ============================================
optimize_php() {
    echo -e "${YELLOW}⚡ Optimizing PHP-FPM...${NC}"
    
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
    PHP_POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    
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
    
    # Update PHP-FPM pool
    sed -i "s/^pm.max_children =.*/pm.max_children = ${MAX_CHILDREN}/" $PHP_POOL
    sed -i "s/^pm.start_servers =.*/pm.start_servers = ${START_SERVERS}/" $PHP_POOL
    sed -i "s/^pm.min_spare_servers =.*/pm.min_spare_servers = ${MIN_SPARE}/" $PHP_POOL
    sed -i "s/^pm.max_spare_servers =.*/pm.max_spare_servers = ${MAX_SPARE}/" $PHP_POOL
    
    # Optimize PHP.ini
    sed -i "s/^memory_limit =.*/memory_limit = ${MEMORY_LIMIT}/" $PHP_INI
    sed -i "s/^max_execution_time =.*/max_execution_time = 300/" $PHP_INI
    sed -i "s/^max_input_time =.*/max_input_time = 300/" $PHP_INI
    sed -i "s/^post_max_size =.*/post_max_size = 64M/" $PHP_INI
    sed -i "s/^upload_max_filesize =.*/upload_max_filesize = 64M/" $PHP_INI
    
    # Enable OPcache
    cat >> $PHP_INI <<EOF

; OPcache Settings
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF
    
    echo -e "${GREEN}   ✅ PHP optimized for ${TOTAL_RAM}MB RAM${NC}"
}

# ============================================
# Nginx with FastCGI Cache
# ============================================
configure_nginx() {
    echo -e "${YELLOW}🚀 Configuring Nginx with FastCGI cache...${NC}"
    
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    
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
    
    # Create cache directory
    mkdir -p /var/cache/nginx
    chown -R www-data:www-data /var/cache/nginx
    
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
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload
    nginx -t && systemctl restart nginx
    
    echo -e "${GREEN}   ✅ Nginx configured with FastCGI cache (${CACHE_SIZE})${NC}"
}

# ============================================
# WordPress Installation
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
    rm -f latest.zip
    
    # Set permissions
    chown -R www-data:www-data wordpress
    chmod -R 755 wordpress
    
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
EOF
    
    echo -e "${GREEN}   ✅ WordPress installed${NC}"
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
# Install Management Commands
# ============================================
install_commands() {
    echo -e "${YELLOW}🔧 Installing management commands...${NC}"
    
    # Create commands directory
    mkdir -p /usr/local/bin
    
    # Main easyinstall command
    cat > /usr/local/bin/easyinstall <<'EOF'
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

case "$1" in
    domain)
        if [ -z "$2" ]; then
            echo -e "${RED}Usage: easyinstall domain yourdomain.com${NC}"
            exit 1
        fi
        echo -e "${YELLOW}🌐 Changing domain to $2...${NC}"
        
        # Update Nginx config
        sed -i "s/server_name _;/server_name $2;/" /etc/nginx/sites-available/wordpress
        nginx -t && systemctl reload nginx
        
        # Update WordPress URLs if wp-cli exists
        if command -v wp &> /dev/null; then
            cd /var/www/html/wordpress
            wp option update home "http://$2"
            wp option update siteurl "http://$2"
        fi
        
        echo -e "${GREEN}✅ Domain updated to $2${NC}"
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
        echo -e "${YELLOW}Next: Run 'certbot --nginx -d $2' for SSL${NC}"
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
                sed -i "s/define('WP_CACHE', false);/define('WP_CACHE', true);/" /var/www/html/wordpress/wp-config.php
                echo -e "${GREEN}✅ Redis cache enabled in WordPress${NC}"
            fi
        fi
        ;;
        
    status)
        echo -e "${YELLOW}📊 System Status:${NC}"
        echo "   • Nginx: $(systemctl is-active nginx)"
        echo "   • PHP-FPM: $(systemctl is-active php*-fpm)"
        echo "   • MariaDB: $(systemctl is-active mariadb)"
        echo "   • Redis: $(systemctl is-active redis-server)"
        echo "   • Fail2ban: $(systemctl is-active fail2ban)"
        echo ""
        echo "   • Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
        echo "   • Memory Usage: $(free -h | awk '/Mem:/ {print $3"/"$2}')"
        echo "   • Cache Size: $(du -sh /var/cache/nginx 2>/dev/null | cut -f1)"
        ;;
        
    help)
        echo "EasyInstall Commands:"
        echo "  easyinstall domain <domain>    - Change WordPress domain"
        echo "  easyinstall migrate <domain>   - Migrate from IP to domain"
        echo "  easyinstall panel enable       - Enable multi-site mode"
        echo "  easyinstall cache clear        - Clear FastCGI cache"
        echo "  easyinstall redis enable       - Enable Redis object cache"
        echo "  easyinstall status             - Show system status"
        echo "  easyinstall help                - Show this help"
        ;;
        
    *)
        echo "EasyInstall Enterprise Stack v2.0"
        echo "Usage: easyinstall [command]"
        echo ""
        echo "Available commands:"
        echo "  domain, migrate, panel, cache, redis, status, help"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/easyinstall
    
    # Create cache clear cron
    echo "0 3 * * * root /usr/local/bin/easyinstall cache clear > /dev/null 2>&1" > /etc/cron.d/easyinstall-cache
    
    echo -e "${GREEN}   ✅ Management commands installed${NC}"
}

# ============================================
# Final Setup
# ============================================
finalize() {
    echo -e "${YELLOW}🎯 Finalizing installation...${NC}"
    
    # Enable services at boot
    systemctl enable nginx mariadb redis-server fail2ban php*-fpm
    
    # Create info file
    cat > /root/easyinstall-info.txt <<EOF
========================================
EasyInstall Enterprise Stack v2.0
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

COMMANDS:
  easyinstall status              - Check system status
  easyinstall domain yourdomain.com - Change domain
  easyinstall migrate yourdomain.com - Migrate to domain
  easyinstall cache clear         - Clear FastCGI cache
  easyinstall panel enable        - Enable multi-site mode

FIREWALL:
  Allowed ports: 22, 80, 443

BACKUP:
  • Database: mysqldump -u ${DB_USER} -p ${DB_NAME} > backup.sql
  • Files: tar -czf wordpress-backup.tar.gz /var/www/html/wordpress

========================================
EOF
    
    # Display completion message
    echo -e "${GREEN}"
    echo "============================================"
    echo "✅ Installation Complete!"
    echo "============================================"
    echo ""
    echo "🌐 WordPress: http://$IP_ADDRESS"
    echo ""
    echo "📊 Database:"
    echo "   Name: ${DB_NAME}"
    echo "   User: ${DB_USER}"
    echo "   Pass: ${DB_PASS}"
    echo ""
    echo "⚡ FastCGI Cache: Active"
    echo "🛡️  Firewall: Active (ports 22,80,443)"
    echo ""
    echo "📝 Info saved to: /root/easyinstall-info.txt"
    echo ""
    echo "🔧 Available commands:"
    echo "   easyinstall status              - Check status"
    echo "   easyinstall domain yourdomain.com - Add domain"
    echo "   easyinstall cache clear         - Clear cache"
    echo ""
    echo "============================================"
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
    install_commands
    finalize
}

# Run main function
main