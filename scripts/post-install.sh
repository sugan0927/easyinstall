#!/bin/bash
# Post-installation tasks

# Create WordPress admin user (optional)
cd /var/www/html/wordpress

# Set proper permissions
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chown -R www-data:www-data .

# Create uploads directory
mkdir -p wp-content/uploads
chmod 775 wp-content/uploads

echo "Post-installation tasks completed"
