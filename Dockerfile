FROM mlocati/php-extension-installer:2.2.11 as php_ext_installer
FROM stephenc/envsub:0.1.3 as envsub
FROM composer/composer:2.7.2-bin as composer
FROM perconalab/percona-toolkit:3.5.7 as pt_toolkit

FROM php:8.1.28-fpm

RUN ln -sr /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

COPY --from=php_ext_installer /usr/bin/install-php-extensions /usr/bin/
RUN install-php-extensions apcu
RUN install-php-extensions bcmath
RUN install-php-extensions blackfire
RUN install-php-extensions calendar
RUN install-php-extensions exif
RUN install-php-extensions gd
RUN install-php-extensions php/pecl-networking-gearman@7033013a1e10add4edb3056a27d62bb4708e942b
RUN install-php-extensions gmagick
RUN install-php-extensions igbinary
RUN install-php-extensions imap
RUN install-php-extensions intl
RUN install-php-extensions newrelic
RUN install-php-extensions opcache
RUN install-php-extensions pcntl
RUN install-php-extensions pdo_mysql
RUN install-php-extensions soap
RUN install-php-extensions sockets
RUN install-php-extensions uuid
RUN install-php-extensions xsl
RUN install-php-extensions zip

RUN echo 'blackfire.apm_enabled = 0' >> /usr/local/etc/php/conf.d/docker-php-ext-blackfire.ini
RUN sed -i -E 's~/var/log/newrelic/.++\.log~/dev/null~' /usr/local/etc/php/conf.d/newrelic.ini

COPY --from=envsub /bin/envsub /usr/bin/envsub
COPY --from=composer /composer /usr/bin/composer
COPY --from=pt_toolkit /usr/bin/pt-online-schema-change /usr/bin/pt-online-schema-change

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    procps \
    libfcgi-bin && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L 'https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/v0.5.0/php-fpm-healthcheck' -o /usr/bin/php-fpm-healthcheck && \
    chmod +x /usr/bin/php-fpm-healthcheck

RUN mkdir -p /tmp/blackfire && curl -L "https://blackfire.io/api/v1/releases/cli/linux/$(uname -m)" | tar zxp -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire /usr/bin/blackfire && rm -Rf /tmp/blackfire

RUN curl -L 'https://github.com/nats-io/natscli/releases/latest/download/nats-0.1.4-amd64.deb' -o /tmp/nats.deb && \
    dpkg -i /tmp/nats.deb && rm -f /tmp/nats.deb

WORKDIR /app

ENV COMPOSER_ALLOW_SUPERUSER=1
