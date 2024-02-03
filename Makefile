#!/usr/bin/make -f

SHELL := /bin/sh
.SHELLFLAGS := -euc

PYTHON_SYS ?= python
PYTHON_ENV ?= ./.venv/bin/python
DOCKER ?= docker

.PHONY: all
all: lint test build

.PHONY: venv
venv:
	@[ -e ./.venv/                ] || $(PYTHON_SYS) -m venv ./.venv/
	@[ -e ./.venv/bin/pip-compile ] || $(PYTHON_ENV) -m pip install 'pip-tools <= 7'

.PHONY: format
format: deps venv
	@$(PYTHON_ENV) -m isort ./src/
	@$(PYTHON_ENV) -m black ./src/

.PHONY: lint
lint: deps venv
	@$(PYTHON_ENV) -m black --check --diff ./src/
	@$(PYTHON_ENV) -m mypy ./src/

.PHONY: test
test: deps venv
	@$(PYTHON_ENV) -m pytest ./src/

.PHONY: build
build: deps venv
	@$(PYTHON_ENV) -m build --wheel

.PHONY: deps
deps: lock venv
	@$(PYTHON_ENV) -m pip install --requirement ./requirements-dev.txt

.PHONY: lock
lock: ./requirements.txt ./requirements-dev.txt

./requirements.txt: ./requirements.in venv
	@$(PYTHON_ENV) -m piptools compile --output-file $@ $<

./requirements-dev.txt: ./requirements-dev.in ./requirements.txt venv
	@$(PYTHON_ENV) -m piptools compile --output-file $@ $<

.PHONY: docker
docker:
	@$(DOCKER) build --tag openapi2jsonschema ./

.PHONY: clean
clean:
	@rm -rf ./.venv/ ./build/ ./dist/