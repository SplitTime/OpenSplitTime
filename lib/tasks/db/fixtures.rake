# Credit to Yi Zeng, https://yizeng.me/2017/07/16/generate-rails-test-fixtures-yaml-from-database-dump/

require_relative "fixture_helper"

namespace :db do
  desc "Convert development database to Rails test fixtures"
  task to_fixtures: :environment do
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.tables.each do |table_name|
      next unless table_name.to_sym.in?(FixtureHelper::FIXTURE_TABLES)

      puts "Computing fixtures for #{table_name}"

      model = table_name.classify.constantize
      model_slugged = model.columns.map(&:name).include?("slug")
      table_portable = table_name.to_sym.in? FixtureHelper::PORTABLE_FIXTURE_TABLES
      belongs_to_associations = model.reflect_on_all_associations(:belongs_to)

      json_column_names = model.columns.select { |c| c.sql_type_metadata.type.in?([:json, :jsonb]) }.map(&:name)

      counter = 0
      file_path = Rails.root.join("spec/fixtures/#{table_name}.yml").to_s
      File.open(file_path, "w") do |file|
        order_clause = FixtureHelper::ORDER_BY_MAP[table_name.to_sym] ||
                       order_clause_for(table_name, table_portable, model_slugged)

        rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name} ORDER BY #{order_clause}")
        data = rows.each_with_object({}) do |record, hash|
          json_column_names.each do |col|
            raw = record[col]
            record[col] = JSON.parse(raw) if raw.is_a?(String)
          end

          counter += 1
          suffix = counter.to_s.rjust(4, "0")
          title = if model_slugged
                    record["slug"].tr("-", "_")
                  elsif table_name == "split_times"
                    effort = Effort.find(record["effort_id"])
                    split = Split.find(record["split_id"])
                    split_name = split.name(record["sub_split_bitkey"]).parameterize.underscore
                    "#{effort.slug.underscore}_#{split_name}_#{record['lap']}"
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
    ActiveRecord::Base.connection&.close
  end

  # Determines the SQL ORDER BY clause used when dumping a table's rows.
  # Non-slug portable tables (other than split_times, which generates content-based titles
  # of its own) MUST have an explicit FixtureHelper::ORDER_BY_MAP entry — there is no safe
  # default, since their `<table>_NNNN` labels depend on row order, and ad-hoc sorts can
  # silently scramble every label and every FK reference whenever a column is added.
  def order_clause_for(table_name, table_portable, model_slugged)
    return "slug" if table_portable && model_slugged
    return "id" unless table_portable && table_name != "split_times"

    raise "Non-slug portable table '#{table_name}' needs an explicit FixtureHelper::ORDER_BY_MAP entry"
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
