FROM php:8.3-apache-bookworm

ARG SUITECRM_VERSION=7.15.2

ENV DEBIAN_FRONTEND=noninteractive \
    APACHE_DOCUMENT_ROOT=/var/www/html

# ============================================================
# System dependencies + PHP extensions
# ============================================================

RUN apt-get update && apt-get install -y --no-install-recommends \
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
    # GD
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    \
    # IMAP
    && docker-php-ext-configure imap \
        --with-kerberos \
        --with-imap-ssl \
    \
    # PHP extensions required by SuiteCRM
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
    # ========================================================
    # Apache MPM
    #
    # PHP is loaded through mod_php, so use prefork.
    # Disable other MPMs to avoid:
    # "More than one MPM loaded"
    # ========================================================
    && a2dismod mpm_event 2>/dev/null || true \
    && a2dismod mpm_worker 2>/dev/null || true \
    && a2dismod mpm_prefork 2>/dev/null || true \
    && a2enmod mpm_prefork \
    \
    # Apache modules required by SuiteCRM
    && a2enmod rewrite \
        headers \
        expires \
    \
    # Apache basic configuration
    && echo 'ServerName localhost' \
        > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    \
    # Railway uses the container port configured here.
    && printf 'Listen 8080\n' > /etc/apache2/ports.conf \
    \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Composer
# ============================================================

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# ============================================================
# Download official SuiteCRM 7.15.2 source
# ============================================================

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
    && COMPOSER_ALLOW_SUPERUSER=1 composer install \
        --no-dev \
        --no-interaction \
        --prefer-dist \
        --optimize-autoloader \
    \
    && rm -rf \
        /opt/suitecrm/.git \
        /opt/suitecrm/tests

# ============================================================
# SuiteCRM / Apache / PHP configuration
# ============================================================

COPY php.ini \
    /usr/local/etc/php/conf.d/99-suitecrm.ini

COPY apache-vhost.conf \
    /etc/apache2/sites-available/000-default.conf

COPY docker-entrypoint.sh \
    /usr/local/bin/docker-entrypoint.sh

COPY suitecrm-cron.sh \
    /usr/local/bin/suitecrm-cron.sh

RUN chmod +x \
        /usr/local/bin/docker-entrypoint.sh \
        /usr/local/bin/suitecrm-cron.sh

# ============================================================
# Verify Apache MPM configuration during image build
# Expected output:
#   mpm_prefork_module (shared)
# ============================================================

RUN echo "============================================" \
    && echo "SuiteCRM Docker image" \
    && echo "SuiteCRM version: ${SUITECRM_VERSION}" \
    && echo "PHP version:" \
    && php -v \
    && echo "Apache MPM configuration:" \
    && apache2ctl -M | grep mpm \
    && echo "============================================"

# ============================================================
# Application directory
# ============================================================

WORKDIR /var/www/html

# ============================================================
# Expose Railway application port
# ============================================================

EXPOSE 8080

# ============================================================
# Container healthcheck
# ============================================================

HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=120s \
    --retries=5 \
    CMD curl -fsS \
        http://127.0.0.1:8080/index.php \
        >/dev/null || exit 1

# ============================================================
# Entrypoint
# ============================================================

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["apache2-foreground"]
