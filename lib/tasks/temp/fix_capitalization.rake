# This is a temporary rake task that should be deleted
# once it has been run in all environments.

require "active_record"
require "active_record/errors"

namespace :temp do
  desc "titleizes fields that are all-lowercase or all-uppercase"
  task fix_capitalization: :environment do
    Rails.application.eager_load!

    models = [::Effort, ::Person, ::User]

    models.each do |model|
      model_name = model.name
      records = model.all
      record_count = records.count

      puts "Updating #{record_count} #{model_name.pluralize}"
      progress_bar = ::ProgressBar.new(record_count)

      records.find_each do |record|
        progress_bar.increment!
        record.send(:capitalize_record)
        record.save!(validate: false)
      rescue ActiveRecordError => e
        puts "Could not save record #{model_name} #{record.id}:"
        puts e
      end

      puts "Finished updating #{model_name}"
    end
  end
end
