namespace :maintenance do
  desc <<~DESC.squish
    Reconciles Subscribable topic_resource_key values against AWS SNS. Reports drift
    (rows whose topic name doesn't match the row's slug) and split into "topic still
    exists in AWS" (harmless slug renames) vs "topic missing in AWS" (dangling
    pointers — the cause of repeated NotifyEventUpdateJob etc. failures).
    Pass APPLY=true to nil out topic_resource_key on the dangling rows.
  DESC
  task reconcile_topic_arns: :environment do
    apply = ENV["APPLY"] == "true"
    klasses = [::Event, ::Effort, ::Person]
    sns_client = ::SnsClientFactory.client

    puts "Mode: #{apply ? 'APPLY (will nil topic_resource_key on dangling rows)' : 'DRY RUN (read-only)'}"
    puts

    klasses.each { |klass| reconcile_class(klass, sns_client, apply: apply) }
  end
end

def reconcile_class(klass, sns_client, apply:)
  drifted = collect_drift(klass)
  if drifted.empty?
    puts "#{klass.name}: no drift"
    return
  end

  puts "#{klass.name}: #{drifted.size} drifted — checking AWS"
  exists = []
  missing = []
  errored = []

  progress = ::ProgressBar.new(drifted.size)
  drifted.each do |record|
    progress.increment!
    begin
      sns_client.get_topic_attributes(topic_arn: record.topic_resource_key)
      exists << record
    rescue ::Aws::SNS::Errors::NotFound
      missing << record
    rescue ::Aws::SNS::Errors::ServiceError => e
      errored << [record, e]
    end
  end

  puts "  exists in AWS (slug-renamed, harmless): #{exists.size}"
  puts "  MISSING in AWS (dangling pointers):     #{missing.size}"
  puts "  errors during AWS check:                #{errored.size}"

  if missing.any?
    puts "\n  Dangling records:"
    missing.each { |r| puts "    #{klass.name}##{r.id}  slug=#{r.slug}  arn=#{r.topic_resource_key}" }
  end

  if errored.any?
    puts "\n  AWS errors (will not be modified):"
    errored.each { |r, e| puts "    #{klass.name}##{r.id}: #{e.class.name}: #{e.message}" }
  end

  return if missing.empty?

  if apply
    cleared = 0
    failed = []
    missing.each do |record|
      record.update_column(:topic_resource_key, nil)
      cleared += 1
    rescue ::ActiveRecord::ActiveRecordError => e
      failed << [record, e]
    end
    puts "\n  Cleared topic_resource_key on #{cleared} #{klass.name.downcase}(s)."
    failed.each { |r, e| puts "    Failed on #{klass.name}##{r.id}: #{e.class.name}: #{e.message}" }
  else
    puts "\n  (dry-run: pass APPLY=true to clear topic_resource_key on the #{missing.size} dangling row(s))"
  end
  puts
end
# rubocop:enable Metrics/MethodLength

def collect_drift(klass)
  klass.where.not(topic_resource_key: nil).find_each.reject do |record|
    # Tolerate both eras (follow_/follow-) and any single-letter env prefix
    # (d-, s-, t-) so this works in non-prod environments too.
    arn_slug = record.topic_resource_key.split(":").last.to_s.sub(/\A([a-z]-)?follow[-_]/, "")
    arn_slug == record.slug
  end
end
