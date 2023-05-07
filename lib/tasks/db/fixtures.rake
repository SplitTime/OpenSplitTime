# frozen_string_literal: true

# Credit to Yi Zeng, https://yizeng.me/2017/07/16/generate-rails-test-fixtures-yaml-from-database-dump/

require_relative "fixture_helper"

namespace :db do
  desc "Convert development database to Rails test fixtures"
  task to_fixtures: :environment do
    PRIMARY_KEY_MAP = {
      "effort_segments" => "begin_split_id, begin_bitkey, end_split_id, end_bitkey, effort_id, lap"
    }.freeze

    begin
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.tables.each do |table_name|
        next unless table_name.to_sym.in?(FixtureHelper::FIXTURE_TABLES)

        counter = 0
        file_path = "#{Rails.root}/spec/fixtures/#{table_name}.yml"
        File.open(file_path, "w") do |file|
          primary_key = PRIMARY_KEY_MAP[table_name] || "id"
          rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name} ORDER BY #{primary_key}")
          data = rows.each_with_object({}) do |record, hash|
            suffix = if record["id"].blank?
                       counter += 1
                       counter.to_s.rjust(4, "0")
                     else
                       record["id"]
                     end
            title = if record["slug"].present?
                      record["slug"].underscore
                    elsif table_name == "split_times"
                      effort = Effort.find(record["effort_id"])
                      split = Split.find(record["split_id"])
                      "#{effort.slug.underscore}_#{split.name(record['sub_split_bitkey']).parameterize.underscore}_#{record['lap']}"
                    elsif table_name == "results_categories"
                      organization = record["organization_id"].present? ? Organization.find(record["organization_id"]) : nil
                      [organization&.name, record["name"]].join(" ").parameterize.underscore
                    else
                      "#{table_name.singularize}_#{suffix}"
                    end
            FixtureHelper::ATTRIBUTES_TO_IGNORE.each do |attr|
              next if attr.in? FixtureHelper::ATTRIBUTES_TO_PRESERVE.fetch(table_name.to_sym, [])
              record.delete(attr.to_s)
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

  desc "Convert Rails test fixtures to development database"
  task from_fixtures: :environment do
    process_start_time = Time.current

    begin
      ActiveRecord::Base.establish_connection
      ENV["FIXTURES_PATH"] = "spec/fixtures"
      ENV["FIXTURES"] = FixtureHelper::FIXTURE_TABLES.join(",")
      ENV["RAILS_ENV"] = "development"
      Rake::Task["db:fixtures:load"].invoke
    ensure
      ActiveRecord::Base.connection&.close
    end

    elapsed_time = Time.current - process_start_time
    puts "\nFinished creating records for #{FixtureHelper::FIXTURE_TABLES.join(', ')} in #{elapsed_time} seconds"
  end
end
