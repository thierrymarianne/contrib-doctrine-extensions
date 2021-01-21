#!/bin/bash

export COMPOSE_PROJECT_NAME='doctrine-extensions'

function build_container_images() {
    if [ ! -e ./docker-compose.override.yml ]; then
        cp ./docker-compose.override.yml{.dist,}
    fi

    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.override.yml \
        build php pgsql mysql
}

function download_composer() {
    if [ -e ./composer.phar ]; then
        echo '[INFO] composer.phar has been downloaded already.'

        return 0
    fi

    local expected_checksum
    expected_checksum="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    local actual_checksum
    actual_checksum="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$expected_checksum" != "$actual_checksum" ]; then
        echo >&2 'ERROR: Invalid installer checksum'
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    result=$?
    rm composer-setup.php

    if [ -e ./composer.phar ]; then
        echo '[INFO] composer.phar has been successfully downloaded.'
    else
        echo '[ERROR] Could not download composer.phar.'
    fi

    return $result
}

function install_dependencies() {
    download_composer &&
        docker-compose \
            -f docker-compose.yml \
            -f docker-compose.override.yml \
            run php /contrib/composer.phar install
}

function set_up_tests() {
    local db
    db="${1}"

    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.override.yml \
        run php /contrib/vendor/bin/phpunit \
        --configuration tests/config/${db}.phpunit.xml.dist \
        tests/Oro/Tests/Connection/SetupTest.php
}

function tear_down_tests() {
    local db
    db="${1}"

    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.override.yml \
        run php /contrib/vendor/bin/phpunit \
        --configuration tests/config/${db}.phpunit.xml.dist \
        tests/Oro/Tests/Connection/TearDownTest.php
}

function run_tests() {
    local db
    db="${1}"

    set_up_tests "${db}"

    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.override.yml \
        run php /contrib/vendor/bin/phpunit \
        -c /contrib/tests/config/"${db}".phpunit.xml.dist

    tear_down_tests "${db}"
}

function run_php_container() {
    docker ps -a | grep 'doctrine-extensions' | grep -v 'CONT' |
        awk '{print $1}' | xargs -I{} docker rm -f {}

    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.override.yml \
        up -d php

    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.override.yml \
        exec php bash
}

function lint_code() {
    docker ps -a | grep 'doctrine-extensions' | grep -v 'CONT' |
        awk '{print $1}' | xargs -I{} docker rm -f {}

    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.override.yml \
        up -d php

    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.override.yml \
        run php /contrib/vendor/bin/phpcs src/ tests/ -p --encoding=utf-8 --extensions=php --standard=psr2
}
alias lint-code='lint_code'
