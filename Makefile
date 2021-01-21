SHELL:=/bin/bash

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build-container-images: ## Build php, mysql and pgsql container images
	@/bin/bash -c 'source ./bin/console.sh && build_container_images'

download-composer: ## Download composer
	@/bin/bash -c 'source ./bin/console.sh && download_composer'

install-dependencies: ## Install dependencies
	@/bin/bash -c 'source ./bin/console.sh && install_dependencies'

run-php-container: ## Run php container
	@/bin/bash -c 'source ./bin/console.sh && run_php_container'

run-mysql-tests: ## Run MySQL tests
	@/bin/bash -c 'source ./bin/console.sh && run_tests mysql'

run-pgsql-tests: ## Run PostgreSQL tests
	@/bin/bash -c 'source ./bin/console.sh && run_tests pgsql'

run-tests: run-mysql-tests run-pgsql-tests ## Run all tests

lint-code: ## Run php code fixer
	@/bin/bash -c 'source ./bin/console.sh && lint_code'

