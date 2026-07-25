web: bundle exec puma -C config/puma.rb -b tcp://127.0.0.1:${PORT}
solid_queue: bundle exec rake solid_queue:start
release: bundle exec rails db:migrate:with_data
