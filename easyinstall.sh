#!/bin/bash

set -e

# ============================================
# EasyInstall Enterprise Stack v2.1
# Ultra-Optimized 512MB VPS → Enterprise Grade Hosting Engine
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 EasyInstall Enterprise Stack v2.1${NC}"
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
# Install Required Packages (with newest PHP)
# ============================================
install_packages() {
    echo -e "${YELLOW}📦 Installing enterprise stack with latest PHP...${NC}"
    
    # Add PHP repository for latest version
    apt update
    apt install -y software-properties-common curl wget
    add-apt-repository ppa:ondrej/php -y
    apt update
    
    # Get latest PHP version
    PHP_VERSION=$(apt-cache search '^php8\.[0-9]-fpm$' | sort -r | head -1 | cut -d' ' -f1 | sed 's/-fpm//')
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION="php8.2"  # Fallback
    fi
    
    echo -e "${YELLOW}   📌 Installing PHP ${PHP_VERSION}...${NC}"
    
    apt install -y nginx mariadb-server ${PHP_VERSION}-fpm ${PHP_VERSION}-mysql \
        ${PHP_VERSION}-cli ${PHP_VERSION}-curl ${PHP_VERSION}-xml ${PHP_VERSION}-mbstring \
        ${PHP_VERSION}-zip ${PHP_VERSION}-gd ${PHP_VERSION}-imagick ${PHP_VERSION}-opcache \
        ${PHP_VERSION}-redis ${PHP_VERSION}-intl \
        redis-server ufw fail2ban curl wget unzip openssl \
        certbot python3-certbot-nginx \
        htop neofetch git cron dnsutils
        
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
    
    # Create cache directory with proper permissions
    mkdir -p /var/cache/nginx
    chown -R www-data:www-data /var/cache/nginx
    chmod -R 755 /var/cache/nginx
    
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
        echo ""
        echo "   • Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
        echo "   • Memory Usage: $(free -h | awk '/Mem:/ {print $3"/"$2}')"
        echo "   • Cache Size: $(du -sh /var/cache/nginx 2>/dev/null | cut -f1)"
        
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
        echo -e "${GREEN}EasyInstall Enterprise Stack v2.1 Commands:${NC}"
        echo ""
        echo -e "${YELLOW}🌐 Domain & SSL:${NC}"
        echo "  easyinstall domain <domain>                    - Change WordPress domain"
        echo "  easyinstall domain <domain> [options]          - Advanced domain update"
        echo "    Options:"
        echo "      -php*v=<version>     Switch PHP version (e.g., -php*v=8.2)"
        echo "      -reinstall           Reinstall WordPress"
        echo "      -cache=<on/off>      Enable/disable cache"
        echo "      -ssl=<on/off>        Enable/disable SSL"
        echo "      -clearcache          Clear cache"
        echo ""
        echo "  Example: easyinstall domain example.com -php*v=8.2 -ssl=on -cache=on -clearcache"
        echo ""
        echo "  easyinstall migrate <domain>   - Migrate from IP to domain"
        echo "  easyinstall ssl <domain> [email] - Install SSL + WordPress plugins"
        echo "  easyinstall reinstall          - Reinstall WordPress (keeps database)"
        echo ""
        echo -e "${YELLOW}🏢 Panel Management:${NC}"
        echo "  easyinstall panel enable       - Enable multi-site mode"
        echo ""
        echo -e "${YELLOW}⚡ Performance:${NC}"
        echo "  easyinstall cache clear        - Clear FastCGI cache"
        echo "  easyinstall redis enable       - Enable Redis object cache"
        echo ""
        echo -e "${YELLOW}📊 System:${NC}"
        echo "  easyinstall status             - Show system status"
        echo "  easyinstall help                - Show this help"
        echo ""
        echo -e "${GREEN}✨ SSL Features:${NC}"
        echo "  • Auto-installs Let's Encrypt SSL"
        echo "  • Installs & configures Nginx Helper plugin"
        echo "  • Installs & enables Redis Object Cache plugin"
        echo "  • Updates WordPress URLs to HTTPS"
        echo "  • Sets up auto-renewal"
        ;;
        
    *)
        echo -e "${GREEN}EasyInstall Enterprise Stack v2.1${NC}"
        echo -e "Usage: ${YELLOW}easyinstall [command]${NC}"
        echo ""
        echo "Available commands:"
        echo "  domain, ssl, migrate, panel, cache, redis, reinstall, status, help"
        echo ""
        echo "Run 'easyinstall help' for detailed usage"
        echo ""
        echo -e "${YELLOW}Advanced domain update example:${NC}"
        echo "  easyinstall domain example.com -php*v=8.2 -ssl=on -cache=on -clearcache"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/easyinstall
    
    # Create cache clear cron
    echo "0 3 * * * root /usr/local/bin/easyinstall cache clear > /dev/null 2>&1" > /etc/cron.d/easyinstall-cache
    
    echo -e "${GREEN}   ✅ Management commands installed (Enhanced version)${NC}"
    
    # Create alias for common typos
    echo "alias asyinstall='easyinstall'" >> /root/.bashrc
    echo "alias easyintall='easyinstall'" >> /root/.bashrc
    echo "alias easinstall='easyinstall'" >> /root/.bashrc
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
    
    # Properly enable PHP-FPM
    echo -e "   🔍 Detecting PHP-FPM service..."
    
    # Get PHP version from installed packages
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
    
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
                    systemctl start php$version-fpm >/dev/null 2>&1
                    echo -e "${GREEN}   ✅ PHP-FPM enabled: php$version-fpm${NC}"
                    PHP_FPM_SERVICE="php$version-fpm"
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
    
    # Create info file
    cat > /root/easyinstall-info.txt <<EOF
========================================
EasyInstall Enterprise Stack v2.1
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
  easyinstall status                    - Check system status
  easyinstall domain yourdomain.com     - Change domain
  easyinstall domain yourdomain.com -php*v=8.2 -ssl=on -cache=on -clearcache  - Advanced update
  easyinstall migrate yourdomain.com    - Migrate to domain
  easyinstall ssl yourdomain.com        - Install SSL + WordPress plugins
  easyinstall reinstall                 - Reinstall WordPress
  easyinstall cache clear                - Clear FastCGI cache
  easyinstall panel enable               - Enable multi-site mode
  easyinstall redis enable               - Enable Redis object cache

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
    echo "📝 Info saved to: /root/easyinstall-info.txt"
    echo ""
    echo -e "${GREEN}✨ New Features:${NC}"
    echo "   • PHP ${PHP_VERSION} (latest stable with intl module)"
    echo "   • Fixed plugin installation permissions"
    echo "   • Advanced domain update with options"
    echo ""
    echo "🔧 Available commands:"
    echo "   easyinstall status                    - Check status"
    echo "   easyinstall domain yourdomain.com     - Add domain"
    echo "   easyinstall ssl yourdomain.com        - Add SSL + plugins"
    echo "   easyinstall reinstall                  - Reinstall WordPress"
    echo ""
    echo -e "${YELLOW}🚀 Advanced domain update:${NC}"
    echo "   easyinstall domain example.com -php*v=8.2 -ssl=on -cache=on -clearcache"
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
