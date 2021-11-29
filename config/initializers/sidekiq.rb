if Rails.env.production?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file("config/schedule.yml")
end
