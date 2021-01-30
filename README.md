# Go-deploy Easy to deploy golang application to server

[![Gem Downloads](https://img.shields.io/gem/dt/scb_easy_api.svg)](https://rubygems.org/gems/go-deploy)
[![Gem-version](https://img.shields.io/gem/v/scb_easy_api.svg)](https://rubygems.org/gems/go-deploy)

## Introduction

The Go-deploy for deploy golang

## Installation

Add this line to your terminal

```sh
gem install go-deploy
```

## Used

create file production.yaml in root project

```yaml
host: <IP>
user: <name>
password: <password>
passphrase: <path to id_rsa>
service:
  name: deploy-go
  env_file: .env.production
  git_repo_url: git@github.com:saharak-manoo/deploy-go.git
  deploy_to: /home/service/deploy-go
  is_restart: true
  copy_files:
    - 'database'
```