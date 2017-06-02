if ENV['RAILS_ENV'] == 'development'
  ActiveRecordQueryTrace.enabled = false
  ActiveRecordQueryTrace.level = :app
  ActiveRecordQueryTrace.ignore_cached_queries = true
  ActiveRecordQueryTrace.colorize = 'light purple'
end
