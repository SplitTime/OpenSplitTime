# frozen_string_literal: true

# Credit to Yi Zeng, https://yizeng.me/2017/07/16/generate-rails-test-fixtures-yaml-from-database-dump/

require_relative "fixture_helper"

namespace :db do
  desc "Convert development database to Rails test fixtures"
  task to_fixtures: :environment do
    begin
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.tables.each do |table_name|
        next unless table_name.to_sym.in?(FixtureHelper::FIXTURE_TABLES)

        puts "Computing fixtures for #{table_name}"

        model = table_name.classify.constantize
        model_slugged = model.columns.map(&:name).include?("slug")
        table_portable = table_name.in? FixtureHelper::PORTABLE_FIXTURE_TABLES
        belongs_to_associations = model.reflect_on_all_associations(:belongs_to)

        counter = 0
        file_path = "#{Rails.root}/spec/fixtures/#{table_name}.yml"
        File.open(file_path, "w") do |file|
          default_primary_key = table_portable ? "slug" : "id"
          primary_key = FixtureHelper::PRIMARY_KEY_MAP[table_name.to_sym] || default_primary_key

          rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name} ORDER BY #{primary_key}")
          data = rows.each_with_object({}) do |record, hash|
            suffix = if record["id"].blank?
                       counter += 1
                       counter.to_s.rjust(4, "0")
                     else
                       record["id"]
                     end
            title = if model_slugged
                      record["slug"].tr("-", "_")
                    elsif table_name == "split_times"
                      effort = Effort.find(record["effort_id"])
                      split = Split.find(record["split_id"])
                      "#{effort.slug.underscore}_#{split.name(record['sub_split_bitkey']).parameterize.underscore}_#{record['lap']}"
                    else
                      "#{table_name.singularize}_#{suffix}"
                    end
            attributes_to_preserve = FixtureHelper::ATTRIBUTES_TO_PRESERVE_BY_TABLE.fetch(table_name.to_sym, [])
            attributes_to_ignore = FixtureHelper::ATTRIBUTES_TO_IGNORE - attributes_to_preserve
            attributes_to_ignore << :id if table_name.to_sym.in? FixtureHelper::PORTABLE_FIXTURE_TABLES
            record.except!(*attributes_to_ignore.map(&:to_s))

            association_hash = {}
            belongs_to_associations.each do |association|
              if association.polymorphic?
                foreign_type = association.foreign_type
                record_parent_type = record[foreign_type]
                record_parent_table = record_parent_type.constantize.table_name
                next unless record_parent_table.to_sym.in? FixtureHelper::PORTABLE_FIXTURE_TABLES

                parent_class = record.delete(foreign_type).constantize
                parent_id = record.delete(association.foreign_key)
                parent = parent_class.find(parent_id)
                parent_title = parent.slug.tr("-", "_")
                association_hash[association.name.to_s] = "#{parent_title} (#{parent_class.name})"
              else
                next unless association.table_name.to_sym.in? FixtureHelper::PORTABLE_FIXTURE_TABLES

                parent_class = association.class_name.constantize
                parent_id = record.delete(association.foreign_key)
                parent = parent_class.find(parent_id)
                association_hash[association.name.to_s] = parent.slug.tr("-", "_")
              end
            end

            hash[title] = association_hash.merge(record)
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
