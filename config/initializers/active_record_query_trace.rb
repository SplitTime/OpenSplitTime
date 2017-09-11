if Rails.env.development? || Rails.env.test?
  ActiveRecordQueryTrace.enabled = true
  ActiveRecordQueryTrace.level = :app
  ActiveRecordQueryTrace.ignore_cached_queries = true
  ActiveRecordQueryTrace.colorize = 'light purple'
  ActiveRecordQueryTrace.lines = 5
end
