FROM php:8.3-apache-bookworm

ARG SUITECRM_VERSION=7.15.2

ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_DOCUMENT_ROOT=/var/www/html

# ------------------------------------------------------------
# System dependencies + PHP extensions
# ------------------------------------------------------------

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        cron \
        git \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libicu-dev \
        libzip-dev \
        libxml2-dev \
        libcurl4-openssl-dev \
        libc-client2007e-dev \
        libkrb5-dev \
        libonig-dev \
    \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    \
    && docker-php-ext-configure imap \
        --with-kerberos \
        --with-imap-ssl \
    \
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
    \
    # --------------------------------------------------------
    # Apache MPM
    # SuiteCRM + mod_php require prefork.
    # Remove every MPM and enable only prefork.
    # --------------------------------------------------------
    && rm -f /etc/apache2/mods-enabled/mpm_*.load \
              /etc/apache2/mods-enabled/mpm_*.conf \
    \
    && a2dismod mpm_event 2>/dev/null || true \
    && a2dismod mpm_worker 2>/dev/null || true \
    && a2dismod mpm_prefork 2>/dev/null || true \
    \
    && rm -f /etc/apache2/mods-enabled/mpm_*.load \
              /etc/apache2/mods-enabled/mpm_*.conf \
    \
    && a2enmod mpm_prefork \
    && a2enmod rewrite \
    && a2enmod headers \
    && a2enmod expires \
    \
    # --------------------------------------------------------
    # Apache configuration
    # --------------------------------------------------------
    && echo 'ServerName localhost' \
        > /etc/apache2/conf-available/servername.conf \
    \
    && a2enconf servername \
    \
    && printf 'Listen 8080\n' \
        > /etc/apache2/ports.conf \
    \
    # --------------------------------------------------------
    # Cleanup
    # --------------------------------------------------------
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Composer
# ------------------------------------------------------------

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# ------------------------------------------------------------
# SuiteCRM source
# ------------------------------------------------------------

WORKDIR /opt

RUN curl -fsSL \
        "https://github.com/SuiteCRM/SuiteCRM/archive/refs/tags/v${SUITECRM_VERSION}.tar.gz" \
        -o /tmp/suitecrm.tar.gz \
    \
    && mkdir -p /opt/suitecrm \
    \
    && tar -xzf /tmp/suitecrm.tar.gz \
        --strip-components=1 \
        -C /opt/suitecrm \
    \
    && rm -f /tmp/suitecrm.tar.gz \
    \
    && cd /opt/suitecrm \
    \
    && COMPOSER_ALLOW_SUPERUSER=1 \
        composer install \
        --no-dev \
        --no-interaction \
        --prefer-dist \
        --optimize-autoloader \
    \
    && rm -rf /opt/suitecrm/.git \
              /opt/suitecrm/tests

# ------------------------------------------------------------
# PHP configuration
# ------------------------------------------------------------

COPY php.ini /usr/local/etc/php/conf.d/99-suitecrm.ini

# ------------------------------------------------------------
# Apache VirtualHost
# ------------------------------------------------------------

COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# ------------------------------------------------------------
# Entrypoint + Scheduler
# ------------------------------------------------------------

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY suitecrm-cron.sh /usr/local/bin/suitecrm-cron.sh

RUN chmod +x \
        /usr/local/bin/docker-entrypoint.sh \
        /usr/local/bin/suitecrm-cron.sh

# ------------------------------------------------------------
# Runtime
# ------------------------------------------------------------

WORKDIR /var/www/html

EXPOSE 8080

# ------------------------------------------------------------
# Build-time Apache validation
# ------------------------------------------------------------

RUN echo "=== Apache MPM configuration ===" \
    && find /etc/apache2/mods-enabled \
        -maxdepth 1 \
        -type l \
        \( -name 'mpm_*.load' -o -name 'mpm_*.conf' \) \
        -printf '%f -> %l\n' \
    && apache2ctl -M 2>&1 \
        | grep -E 'mpm_(event|worker|prefork)_module' \
    && echo "=== Apache configuration test ===" \
    && apache2ctl -t

# ------------------------------------------------------------
# Healthcheck
# ------------------------------------------------------------

HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=120s \
    --retries=5 \
    CMD curl -fsS \
        http://127.0.0.1:8080/index.php \
        >/dev/null || exit 1

# ------------------------------------------------------------
# Startup
# ------------------------------------------------------------

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["apache2-foreground"]
