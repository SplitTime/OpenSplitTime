# frozen_string_literal: true

# Credit to Yi Zeng, https://yizeng.me/2017/07/16/generate-rails-test-fixtures-yaml-from-database-dump/

require_relative "fixture_helper"

namespace :db do
  desc "Convert development database to Rails test fixtures"
  task to_fixtures: :environment do
    PRIMARY_KEY_MAP = {
      effort_segments: "begin_split_id, begin_bitkey, end_split_id, end_bitkey, effort_id, lap",
      results_categories: "identifier",
      results_templates: "identifier",
    }.freeze

    begin
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.tables.each do |table_name|
        next unless table_name.to_sym.in?(FixtureHelper::FIXTURE_TABLES)

        puts "Converting #{table_name}..."
        klass = table_name.classify.constantize
        belongs_to_relations = klass.reflect_on_all_associations(:belongs_to)

        counter = 0
        file_path = "#{Rails.root}/spec/fixtures/#{table_name}.yml"
        File.open(file_path, "w") do |yaml|
          primary_key = PRIMARY_KEY_MAP.fetch(table_name.to_sym, "id")
          use_identifier = primary_key == "identifier"
          yaml_hash = {}

          records = klass.all.order(primary_key)
          records.each do |record|
            suffix = if record["id"].blank?
                       counter += 1
                       counter.to_s.rjust(4, "0")
                     else
                       record["id"]
                     end
            title = if use_identifier
                      record["identifier"]
                    elsif record["slug"].present?
                      record["slug"].tr("-", "_")
                    elsif table_name == "split_times"
                      effort = Effort.find(record["effort_id"])
                      split = Split.find(record["split_id"])
                      "#{effort.slug.tr("-", "_")}_#{split.name(record['sub_split_bitkey']).parameterize.tr("-", "_")}_#{record['lap']}"
                    else
                      "#{table_name.singularize}_#{suffix}"
                    end

            attributes_to_ignore = FixtureHelper::ATTRIBUTES_TO_IGNORE -
              FixtureHelper::ATTRIBUTES_TO_PRESERVE_BY_TABLE.fetch(table_name.to_sym, [])
            attributes_to_ignore << :id if use_identifier
            attributes_to_ignore.map!(&:to_s)
            attributes = record.attributes.except(*attributes_to_ignore).slice(*klass.column_names)
            attributes.transform_values! { |value| value.respond_to?(:strftime) ? value.to_s : value }

            belongs_to_relations.each do |relation|
              parent_class = relation.class_name.constantize
              next if parent_class.class == Module
              next unless parent_class.column_names.include?("identifier")

              parent_id = attributes.delete(relation.foreign_key)
              attributes[relation.name.to_s] = parent_class.find(parent_id).identifier
            end

            yaml_hash[title] = attributes
          end

          puts "Writing table '#{table_name}' to '#{file_path}'"
          yaml.puts(yaml_hash.to_yaml)
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
