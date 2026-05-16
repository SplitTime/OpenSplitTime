# Reconciles Subscribable topic_resource_key values against AWS SNS. For every
# row with a topic_resource_key, calls GetTopicAttributes and classifies:
#   - exists in AWS, slug matches the ARN (healthy)
#   - exists in AWS, slug differs from the ARN (drift — harmless slug rename)
#   - missing in AWS (dangling pointer — what causes NotifyEventUpdateJob etc.
#     to fail and self-heal repeatedly)
# Pass APPLY=true to nil topic_resource_key on the dangling rows.
namespace :maintenance do
  desc "Reports topic_resource_key vs AWS; APPLY=true clears dangling pointers"
  task reconcile_topic_arns: :environment do
    apply = ENV["APPLY"] == "true"
    klasses = [::Event, ::Effort]
    # Pass logger: nil so the aws-sdk-rails railtie's per-call INFO logging
    # doesn't drown the progress bar in one line per GetTopicAttributes.
    sns_client = ::SnsClientFactory.client(logger: nil)

    puts "Mode: #{apply ? 'APPLY (will nil topic_resource_key on dangling rows)' : 'DRY RUN (read-only)'}"
    puts

    klasses.each { |klass| reconcile_class(klass, sns_client, apply: apply) }
  end
end

def reconcile_class(klass, sns_client, apply:)
  scope = klass.where.not(topic_resource_key: nil)
  total = scope.count
  if total.zero?
    puts "#{klass.name}: no rows with topic_resource_key"
    return
  end

  puts "#{klass.name}: #{total} row(s) — checking AWS"
  exists_matched = 0
  exists_drifted = 0
  missing = []
  errored = []

  progress = ::ProgressBar.new(total)
  scope.find_each do |record|
    progress.increment!
    begin
      sns_client.get_topic_attributes(topic_arn: record.topic_resource_key)
      slug_matches_arn?(record) ? exists_matched += 1 : exists_drifted += 1
    rescue ::Aws::SNS::Errors::NotFound
      missing << record
    rescue ::Aws::SNS::Errors::ServiceError => e
      errored << [record, e]
    end
  end

  puts "  exists in AWS (slug matches):           #{exists_matched}"
  puts "  exists in AWS (slug-renamed, harmless): #{exists_drifted}"
  puts "  MISSING in AWS (dangling pointers):     #{missing.size}"
  puts "  errors during AWS check:                #{errored.size}"

  if missing.any?
    puts "\n  Dangling rows:"
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

def slug_matches_arn?(record)
  # Tolerate both eras (follow_/follow-) and any single-letter env prefix
  # (d-, s-, t-) so this works in non-prod environments too.
  arn_slug = record.topic_resource_key.split(":").last.to_s.sub(/\A([a-z]-)?follow[-_]/, "")
  arn_slug == record.slug
end
