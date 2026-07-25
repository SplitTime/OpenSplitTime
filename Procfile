web: bundle exec puma -C config/puma.rb -b tcp://127.0.0.1:${PORT}
solid_queue: bundle exec rails solid_queue:start
release: bundle exec rails db:migrate:with_data
