FROM mlocati/php-extension-installer:2.9.13 AS php_ext_installer
FROM composer/composer:2.8.12-bin AS composer

FROM php:8.3.27-fpm-bookworm

RUN ln -sr /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    percona-toolkit \
    procps \
    libfcgi-bin \
    ghostscript && \
    rm -rf /var/lib/apt/lists/*

COPY --from=composer /composer /usr/bin/composer
COPY --from=php_ext_installer /usr/bin/install-php-extensions /usr/bin/

RUN install-php-extensions bcmath
RUN install-php-extensions calendar
RUN install-php-extensions exif
RUN install-php-extensions ftp
RUN install-php-extensions gd
RUN install-php-extensions imap
RUN install-php-extensions intl
RUN install-php-extensions opcache
RUN install-php-extensions pcntl
RUN install-php-extensions pdo_mysql
RUN install-php-extensions soap
RUN install-php-extensions sockets
RUN install-php-extensions xsl

# https://pecl.php.net/package/gmagick
RUN install-php-extensions gmagick

# renovate: datasource=github-releases depName=ext-apcu packageName=krakjoe/apcu
ENV EXT_APCU_VERSION=5.1.27
RUN install-php-extensions apcu-${EXT_APCU_VERSION}

# renovate: datasource=deb depName=ext-blackfire packageName=blackfire-php registryUrl=https://packages.blackfire.io/debian?dist=any&components=main&binaryArch=all&suite=stable
ENV EXT_BLACKFIRE_VERSION=1.92.48
RUN install-php-extensions blackfire-${EXT_BLACKFIRE_VERSION}

# renovate: datasource=github-releases depName=ext-newrelic packageName=newrelic/newrelic-php-agent
ENV EXT_NEWRELIC_VERSION=12.1.0.26
RUN IPE_NEWRELIC_DAEMON=0 IPE_NEWRELIC_KEEPLOG=0 install-php-extensions newrelic-${EXT_NEWRELIC_VERSION}

# renovate: datasource=github-releases depName=ext-redis packageName=phpredis/phpredis
ENV EXT_REDIS_VERSION=6.2.0
RUN install-php-extensions redis-${EXT_REDIS_VERSION}

# renovate: datasource=github-tags depName=ext-uuid packageName=php/pecl-networking-uuid
ENV EXT_UUID_VERSION=1.3.0
RUN install-php-extensions uuid-${EXT_UUID_VERSION}

# renovate: datasource=github-tags depName=ext-zip packageName=pierrejoye/php_zip
ENV EXT_ZIP_VERSION=1.22.3
RUN install-php-extensions zip-${EXT_ZIP_VERSION}

RUN mkdir -p /tmp/blackfire && curl -L "https://blackfire.io/api/v1/releases/cli/linux/$(uname -m)" | tar zxp -C /tmp/blackfire && \
    mv /tmp/blackfire/blackfire /usr/bin/blackfire && rm -Rf /tmp/blackfire
RUN echo 'blackfire.apm_enabled = 0' >> /usr/local/etc/php/conf.d/docker-php-ext-blackfire.ini
RUN echo 'newrelic.enabled = 0' >> /usr/local/etc/php/conf.d/newrelic.ini
RUN echo 'newrelic.daemon.dont_launch = 3' >> /usr/local/etc/php/conf.d/newrelic.ini
RUN echo 'newrelic.loglevel = "warning"' >> /usr/local/etc/php/conf.d/newrelic.ini
RUN sed -i -E 's~/var/log/newrelic/.++\.log~/dev/stderr~' /usr/local/etc/php/conf.d/newrelic.ini

WORKDIR /app

ENV COMPOSER_ALLOW_SUPERUSER=1
