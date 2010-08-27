#!/bin/bash

DB_PASSWORD=''

#################################
#	system update		#
#################################

function lemp_system_update_aptitude {

#set console encoding so user isn't prompted. this was needed for the 8.04 SS and I won't remove it since it doesn't hurt anything.
	echo "console-setup console-setup/charmap select UTF-8" | debconf-set-selections

#i prefer aptitude. you may not.
	aptitude update
	aptitude -y full-upgrade #only sissies use safe-upgrade. ARE YOU A SISSY?

#need wget.
	aptitude install -y wget

}


#################################
#	mysql install		#
#################################

function lemp_mysql_install {

	echo "mysql-server-5.1 mysql-server/root_password password $DB_PASSWORD" | debconf-set-selections
	echo "mysql-server-5.1 mysql-server/root_password_again password $DB_PASSWORD" | debconf-set-selections
	aptitude -y install mysql-server mysql-client

}

#################################
#	PHP-FPM			#
#################################

function lemp_php-fpm {

#check for versions of php and suhosin patch and extensions
#
# http://php.net/
# http://www.hardened-php.net/suhosin/download.html
#
#and alter variables as necessary
PHP_VER=5.3.3
SUHOSIN_PATCH_VER=0.9.10
SUHOSIN_VER=0.9.32.1

#dependencies for all the crap to be included with php
	aptitude install -y libcurl4-openssl-dev libjpeg62-dev libpng12-dev libxpm-dev libfreetype6-dev libt1-dev libmcrypt-dev libxslt1-dev libbz2-dev libxml2-dev libevent-dev

#not php specific deps
	aptitude install -y wget build-essential autoconf2.13 subversion

#create directory to play in
	mkdir /tmp/phpcrap
	cd /tmp/phpcrap

#grab php.
	wget "http://us.php.net/get/php-$PHP_VER.tar.bz2/from/us.php.net/mirror"
	tar -xjvf "php-$PHP_VER.tar.bz2"

#grab suhosin.
	wget "http://download.suhosin.org/suhosin-patch-$PHP_VER-$SUHOSIN_PATCH_VER.patch.gz"
	gunzip "suhosin-patch-$PHP_VER-$SUHOSIN_PATCH_VER.patch.gz"

#patch php with suhosin.
	cd "php-$PHP_VER"
	patch -p 1 -i "../suhosin-patch-$PHP_VER-$SUHOSIN_PATCH_VER.patch"

#build php
	./configure --with-config-file-path=/usr/local/lib/php --with-curl --enable-exif --with-gd --with-jpeg-dir --with-png-dir --with-zlib --with-xpm-dir --with-freetype-dir --with-t1lib --with-mcrypt --with-mhash --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-openssl --enable-sysvmsg --enable-wddx --with-xsl --enable-zip --with-bz2 --enable-bcmath --enable-calendar --enable-ftp --enable-mbstring --enable-soap --enable-sockets --enable-sqlite-utf8 --with-gettext --enable-shmop --with-xmlrpc --enable-dba --enable-sysvsem --enable-sysvshm --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data
	make

#install php
	make install

#move php.ini to where php-fpm looks for it
	cp "/tmp/phpcrap/php-$PHP_VER/php.ini-production" /usr/local/lib/php/php.ini

#set permissions
	chmod 644 /usr/local/lib/php/php.ini

#place php-fpm config and init script where they belong
	cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
	cp "/tmp/phpcrap/php-$PHP_VER/sapi/fpm/init.d.php-fpm" /etc/init.d/php-fpm
	chmod 755 /etc/init.d/php-fpm

#grab and install suhosin extension.
	cd ../
	wget "http://download.suhosin.org/suhosin-$SUHOSIN_VER.tar.gz"
	tar -xzvf "suhosin-$SUHOSIN_VER.tar.gz"
	cd "suhosin-$SUHOSIN_VER"
	/usr/local/bin/phpize
	./configure
	make
	make install

#make php use it.
	echo "extension = suhosin.so" >> /usr/local/lib/php/php.ini

#have /etc/init.d/php-fpm run on boot
	update-rc.d php-fpm defaults

#/etc/php-fpm.conf stuff
#
#sockets > ports. Using the 127.0.0.1:9000 stuff needlessly introduces TCP/IP overhead.
	sed -i 's/listen = 127.0.0.1:9000/listen = \/usr\/local\/var\/run\/php-fpm.sock/' /usr/local/etc/php-fpm.conf
#
#nice strict permissions
	sed -i "s/;listen.owner = www-data/listen.owner = www-data/" /usr/local/etc/php-fpm.conf
	sed -i "s/;listen.group = www-data/listen.group = www-data/" /usr/local/etc/php-fpm.conf
	sed -i 's/;listen.mode = 0666/listen.mode = 0600/' /usr/local/etc/php-fpm.conf
#
#these settings are fairly conservative and can probably be increased without things melting
	sed -i 's/pm.max_children = 50/pm.max_children = 12/' /usr/local/etc/php-fpm.conf
	sed -i 's/;pm.start_servers = 20/pm.start_servers = 4/' /usr/local/etc/php-fpm.conf
	sed -i 's/;pm.min_spare_servers = 5/pm.min_spare_servers = 2/' /usr/local/etc/php-fpm.conf
	sed -i 's/;pm.max_spare_servers = 35/pm.max_spare_servers = 4/' /usr/local/etc/php-fpm.conf
	sed -i 's/;pm.max_requests = 500/pm.max_requests = 500/' /usr/local/etc/php-fpm.conf
#
#enable pid so init script won't report "fail"
	sed -i 's/;pid = \/usr\/local\/var\/run\/php-fpm.pid/pid = \/usr\/local\/var\/run\/php-fpm.pid/' /usr/local/etc/php-fpm.conf
	
#Engage.
        /etc/init.d/php-fpm start

#remove build crap
	rm -rf /tmp/phpcrap
	rm -rf /tmp/pear

}


#################################
#	nginx			#
#################################

function lemp_nginx {

#install it.
	aptitude install nginx

#consensus of nginx mailing list seems to be children should be a multiple of available processors. considering nginx's asynchronous nature, 4 is plenty.
	sed -i 's/worker_processes\ \ 1/worker_processes\ 4/' /etc/nginx/nginx.conf

#Make it so.
	/etc/init.d/nginx start

}

#################################
#	Git			#
#################################
function lemp_git {

#install it.
	aptitude -y install git-core
}


lemp_system_update_aptitude
lemp_mysql_install
lemp_php-fpm
lemp_nginx
lemp_git
