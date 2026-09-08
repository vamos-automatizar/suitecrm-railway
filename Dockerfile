FROM php:8.3-apache-bookworm

ENV APACHE_DOCUMENT_ROOT=/var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        unzip \
        git \
        cron \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libicu-dev \
        libzip-dev \
        libxml2-dev \
        libcurl4-openssl-dev \
        libc-client2007e-dev \
        libkrb5-dev \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-configure imap \
        --with-kerberos \
        --with-imap-ssl \
    && docker-php-ext-install -j"$(nproc)" \
        curl \
        gd \
        intl \
        imap \
        mbstring \
        mysqli \
        pdo_mysql \
        soap \
        xml \
        zip \
    && a2enmod rewrite headers expires \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /opt

RUN curl -fsSL \
        "https://github.com/SuiteCRM/SuiteCRM/archive/refs/tags/v7.15.2.tar.gz" \
        -o /tmp/suitecrm.tar.gz \
    && mkdir -p /opt/suitecrm \
    && tar -xzf /tmp/suitecrm.tar.gz \
        --strip-components=1 \
        -C /opt/suitecrm \
    && rm -f /tmp/suitecrm.tar.gz \
    && cd /opt/suitecrm \
    && composer install \
        --no-dev \
        --no-interaction \
        --prefer-dist \
        --optimize-autoloader \
    && rm -rf /opt/suitecrm/.git /opt/suitecrm/tests

COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf
COPY php.ini /usr/local/etc/php/conf.d/99-suitecrm.ini
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY suitecrm-cron.sh /usr/local/bin/suitecrm-cron.sh

RUN chmod +x \
        /usr/local/bin/docker-entrypoint.sh \
        /usr/local/bin/suitecrm-cron.sh \
    && echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    && printf "Listen 8080\n" > /etc/apache2/ports.conf

WORKDIR /var/www/html

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
