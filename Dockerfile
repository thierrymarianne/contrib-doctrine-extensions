FROM php:7.4.2-cli-buster

RUN apt-get update && apt-get install -y wget unzip git libicu-dev libpq-dev libcurl4-gnutls-dev && \
    docker-php-ext-install bcmath intl pdo_pgsql mysqli pcntl pdo_mysql && \
    cd /tmp && \
    wget https://xdebug.org/files/xdebug-2.9.2.tgz && \
    tar -xvzf xdebug-2.9.2.tgz && \
    cd xdebug-2.9.2 && \
    phpize . && ./configure --with-php-config=`which php-config` && \
    make && make install && \
    docker-php-ext-install sockets

VOLUME /contrib

WORKDIR /contrib

CMD ["tail", "-f", "/dev/null"]