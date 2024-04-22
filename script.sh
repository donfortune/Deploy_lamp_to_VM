#!/bin/bash

# Update your Linux system
sudo apt update

# Install your Apache web server
sudo apt install apache2

# Add the PHP Ondrej repository if not added already
if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    sudo add-apt-repository ppa:ondrej/php
fi

# Update your repository again
sudo apt update

# Install PHP 8.2 if not installed already
if ! command -v php8.2 &> /dev/null; then
    sudo apt install php8.2
fi

# Install some of those PHP dependencies that are needed for Laravel to work
sudo apt install php8.2-curl php8.2-dom php8.2-mbstring php8.2-xml php8.2-mysql zip unzip

# Enable rewrite
sudo a2enmod rewrite

# Restart your Apache server
sudo systemctl restart apache2

# Change directory in the bin directory
cd /usr/bin

# Install Composer if not installed already
if ! command -v composer &> /dev/null; then
    sudo curl -sS https://getcomposer.org/installer | sudo php
    sudo mv composer.phar composer
fi

# Change directory to /var/www directory so we can clone Laravel repo there
cd /var/www/

# Clone Laravel repository if not cloned already
if [ ! -d "laravel" ]; then
    sudo git clone https://github.com/laravel/laravel.git
    sudo chown -R $USER:$USER /var/www/laravel
fi

cd laravel/

# Install Composer autoloader
composer install --optimize-autoloader --no-dev
composer update

# Copy the content of the default env file to .env if .env doesn't exist
if [ ! -f ".env" ]; then
    sudo cp .env.example .env
fi

sudo chown -R www-data storage
sudo chown -R www-data bootstrap/cache

cd

cd /etc/apache2/sites-available/

# Create latest.conf if it doesn't exist
if [ ! -f "latest.conf" ]; then
    sudo touch latest.conf
    echo '<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/laravel/public

    <Directory /var/www/laravel>
        AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/laravel-error.log
    CustomLog ${APACHE_LOG_DIR}/laravel-access.log combined
</VirtualHost>' | sudo tee /etc/apache2/sites-available/latest.conf
fi

sudo a2ensite latest.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2

cd

# Install MySQL server and client if not installed already
sudo apt install -y mysql-server mysql-client

# Start MySQL service if not already started
sudo systemctl start mysql

# Create MySQL database and user if not exist already
sudo mysql -uroot -e "CREATE DATABASE IF NOT EXISTS Altschool;"
sudo mysql -uroot -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'osowoayi1';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON Altschool.* TO 'wpuser'@'localhost';"

cd /var/www/laravel

# Uncomment and update database configurations in .env file
sudo sed -i "23 s/^#//g" /var/www/laravel/.env
sudo sed -i "24 s/^#//g" /var/www/laravel/.env
sudo sed -i "25 s/^#//g" /var/www/laravel/.env
sudo sed -i "26 s/^#//g" /var/www/laravel/.env
sudo sed -i "27 s/^#//g" /var/www/laravel/.env
sudo sed -i '22 s/=sqlite/=mysql/' /var/www/laravel/.env
sudo sed -i '23 s/=127.0.0.1/=localhost/' /var/www/laravel/.env
sudo sed -i '24 s/=3306/=3306/' /var/www/laravel/.env
sudo sed -i '25 s/=laravel/=Altschool/' /var/www/laravel/.env
sudo sed -i '26 s/=root/=wpuser/' /var/www/laravel/.env
sudo sed -i '27 s/=/=osowoayi1/' /var/www/laravel/.env

# Generate Laravel application key
sudo php artisan key:generate

# Create symbolic link for storage
sudo php artisan storage:link

# Run Laravel migrations
sudo php artisan migrate

# Seed the database
sudo php artisan db:seed

# Restart Apache server
sudo systemctl restart apache2
