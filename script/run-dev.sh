#!/usr/bin/env bash

export NODE_OPTIONS='--openssl-legacy-provider'
bundle exec rails s -b 0.0.0.0
