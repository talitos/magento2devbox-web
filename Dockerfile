FROM php:7.0.12-fpm
MAINTAINER "Talos Digital"

ENV PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=magento2 --with-fpm-group=magento2"

RUN apt-get update && apt-get install -y \
    apt-utils \
    sudo \
    wget \
    unzip \
    cron \
    curl \
    libmcrypt-dev \
    libicu-dev \
    libxml2-dev libxslt1-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng12-dev \
    git \
    vim \
    openssh-server \
    supervisor \
    mysql-client \
    ocaml \
    expect \
    telnet \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-install -j$(nproc) mcrypt intl xsl gd zip pdo_mysql opcache soap bcmath json iconv \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && pecl install xdebug && docker-php-ext-enable xdebug \
    && echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_host=10.254.254.254" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.max_nesting_level=1000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=true" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && chmod 666 /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && mkdir /var/run/sshd \
    && apt-get clean && apt-get update && apt-get install -y nodejs \
    && ln -s /usr/bin/nodejs /usr/bin/node \
    && apt-get install -y npm \
    && npm update -g npm && npm install -g grunt-cli && npm install -g gulp \
    && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
    && apt-get install -y apache2 \
    && a2enmod rewrite \
    && a2enmod proxy \
    && a2enmod proxy_fcgi \
    && rm -f /etc/apache2/sites-enabled/000-default.conf \
    && useradd -m -d /home/magento2 -s /bin/bash magento2 && adduser magento2 sudo \
    && echo "magento2:magento2" | chpasswd \
    && touch /etc/sudoers.d/privacy \
    && echo "Defaults        lecture = never" >> /etc/sudoers.d/privacy \
    && mkdir /home/magento2/magento2 && mkdir /var/www/magento2 \
    && mkdir /home/magento2/state \
    && curl -sS https://accounts.magento.cloud/cli/installer -o /home/magento2/installer \
    && rm -r /usr/local/etc/php-fpm.d/* \
    && sed -i 's/www-data/magento2/g' /etc/apache2/envvars

# PHP config
ADD conf/php.ini /usr/local/etc/php

# SSH config
COPY conf/sshd_config /etc/ssh/sshd_config
RUN chown magento2:magento2 /etc/ssh/ssh_config

# supervisord config
ADD conf/supervisord.conf /etc/supervisord.conf

# php-fpm config
ADD conf/php-fpm-magento2.conf /usr/local/etc/php-fpm.d/php-fpm-magento2.conf

# apache config
ADD conf/apache-default.conf /etc/apache2/sites-enabled/apache-default.conf

# Postfix
run echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt
run echo "postfix postfix/mailname string mail.example.com" >> preseed.txt
run debconf-set-selections preseed.txt
run DEBIAN_FRONTEND=noninteractive apt-get install -q -y postfix
run postconf -e myhostname=mail.example.com
run postconf -e mydestination="mail.example.com, example.com, localhost.localdomain, localhost"
run postconf -e mail_spool_directory="/var/spool/mail/"
run postconf -e mailbox_command=""

ADD conf/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV PATH $PATH:/home/magento2/scripts/:/home/magento2/.magento-cloud/bin
ENV PATH $PATH:/var/www/magento2/bin

ENV SHARED_CODE_PATH /var/www/magento2
ENV WEBROOT_PATH /var/www/magento2
ENV MAGENTO_ENABLE_SYNC_MARKER 0

# Initial scripts
COPY scripts/ /home/magento2/scripts/
RUN sed -i 's/^/;/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i 's/^;;*//' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN chown -R magento2:magento2 /home/magento2 && \
    chown -R magento2:magento2 /var/www/magento2

EXPOSE 80 22 5000 9000 44100
WORKDIR /home/magento2

USER root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
