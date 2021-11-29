# frozen_string_literal: true

# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server
workers Integer(ENV["WEB_CONCURRENCY"] || 2)
threads_count = Integer(ENV["RAILS_MAX_THREADS"] || 2)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV["PORT"]     || 3000
environment ENV["RACK_ENV"] || "development"

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end

# Set a long timeout in development and test environments
# to allow for more effective debugging.
if %w(development test).include?(ENV["RACK_ENV"])
  worker_timeout 10.minutes
end
