FROM mlocati/php-extension-installer:2.1.50 as php_ext_installer

FROM php:8.1.23-fpm

COPY --from=php_ext_installer /usr/bin/install-php-extensions /usr/bin/
RUN install-php-extensions apcu
RUN install-php-extensions bcmath
RUN install-php-extensions calendar
RUN install-php-extensions exif
RUN install-php-extensions gd
RUN install-php-extensions php/pecl-networking-gearman@7033013a1e10add4edb3056a27d62bb4708e942b
RUN install-php-extensions gmagick
RUN install-php-extensions igbinary
RUN install-php-extensions imap
RUN install-php-extensions intl
RUN install-php-extensions opcache
RUN install-php-extensions pcntl
RUN install-php-extensions pdo_mysql
RUN install-php-extensions soap
RUN install-php-extensions sockets
RUN install-php-extensions zip
RUN install-php-extensions xsl

RUN curl -L "https://download.newrelic.com/php_agent/release/newrelic-php5-10.11.0.3-linux.tar.gz" --output /tmp/newrelic.tar.gz && \
    cd /tmp && \
    tar -xf newrelic.tar.gz && \
    cd newrelic-* && \
    NR_INSTALL_SILENT=true ./newrelic-install install && \
    cp --remove-destination "$(readlink "$(php -r "echo ini_get ('extension_dir');")/newrelic.so")" "$(php -r "echo ini_get ('extension_dir');")/newrelic.so" && \
    rm -rf /tmp/newrelic*

WORKDIR /app
