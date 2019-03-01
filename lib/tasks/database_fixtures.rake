# frozen_string_literal: true

# Credit to Yi Zeng, https://yizeng.me/2017/07/16/generate-rails-test-fixtures-yaml-from-database-dump/

namespace :db do
  desc 'Convert development database to Rails test fixtures'
  task to_fixtures: :environment do
    TABLES_TO_SKIP = %w[ar_internal_metadata delayed_jobs schema_info schema_migrations friendly_id_slugs locations active_storage_blobs active_storage_attachments].freeze

    begin
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.tables.each do |table_name|
        next if table_name.in?(TABLES_TO_SKIP)

        counter = 0
        file_path = "#{Rails.root}/spec/fixtures/#{table_name}.yml"
        File.open(file_path, 'w') do |file|
          rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name} ORDER BY id")
          data = rows.each_with_object({}) do |record, hash|
            suffix = if record['id'].blank?
                       counter += 1
                       counter.to_s.rjust(4, '0')
                     else
                       record['id']
                     end
            title = case
                    when record['slug'].present?
                      record['slug'].underscore
                    when table_name == 'split_times'
                      effort = Effort.find(record['effort_id'])
                      split = Split.find(record['split_id'])
                      "#{effort.slug.underscore}_#{split.name(record['sub_split_bitkey']).parameterize.underscore}_#{record['lap']}"
                    when table_name == 'results_categories'
                      organization = record['organization_id'].present? ? Organization.find(record['organization_id']) : nil
                      [organization&.name, record['name']].join(' ').parameterize.underscore
                    else
                      "#{table_name.singularize}_#{suffix}"
                    end
            hash[title] = record
          end
          puts "Writing table '#{table_name}' to '#{file_path}'"
          file.write(data.to_yaml)
        end
      end
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
    end
  end

  desc 'Convert Rails test fixtures to development database'
  task from_fixtures: :environment do
    process_start_time = Time.current

    TABLES_TO_SKIP = %w[ar_internal_metadata delayed_jobs schema_info schema_migrations friendly_id_slugs locations].freeze

    begin
      ActiveRecord::Base.establish_connection
      table_names = ActiveRecord::Base.connection.tables - TABLES_TO_SKIP
      ENV['FIXTURES_PATH'] = 'spec/fixtures'
      ENV['FIXTURES'] = table_names.join(',')
      ENV['RAILS_ENV'] = 'development'
      Rake::Task['db:fixtures:load'].invoke

    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
    end

    elapsed_time = Time.current - process_start_time
    puts "\nFinished creating records for #{to_sentence(table_names)} in #{elapsed_time} seconds"
  end
end
