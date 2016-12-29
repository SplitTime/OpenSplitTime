if ENV['RAILS_ENV'] == 'development'
  ActiveRecordQueryTrace.enabled = true
  ActiveRecordQueryTrace.level = :app
  ActiveRecordQueryTrace.ignore_cached_queries = true
  ActiveRecordQueryTrace.colorize = 'light purple'
end