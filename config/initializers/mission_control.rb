# frozen_string_literal: true

# Disable HTTP basic auth for Mission Control
# Authentication is handled by Devise in routes.rb
MissionControl::Jobs.http_basic_auth_enabled = false
