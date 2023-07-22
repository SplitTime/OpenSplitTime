# frozen_string_literal: true

# This prevents authentication failure error messages from appearing in the test output.
OmniAuth.config.logger = Rails.logger
