namespace :paperclip do

  desc 'Convert url references to paperclip attachments'
  task :convert_url => :environment do
    puts "Starting task"

    klass = Paperclip::Task.obtain_class.constantize
    url_field = ENV['URL_FIELD'] || ENV['url_field']
    attachment_field = ENV['ATTACHMENT'] || ENV['attachment']
    attachment_file_name_field = "#{attachment_field}_file_name"

    records = klass.where.not(url_field => nil)

    skipped_records = []
    saved_records = []
    unsaved_records = []
    file_missing_records = []

    puts "#{records.size} records found with urls"

    records.each do |record|
      if record.photo.present?
        print 'O'
        skipped_records << record
      else
        url = record.send(url_field)
        file_name = url.split('/').last
        file = FileStore.get(url)

        if file
          record.assign_attributes(attachment_field => file, attachment_file_name_field => file_name)
          if record.save
            print '.'
            saved_records << record
          else
            print 'X'
            unsaved_records << record
          end
        else
          print '-'
          file_missing_records << record
        end
      end
    end

    puts "\nGenerating thumbnails"

    Rake::Task["paperclip:refresh:thumbnails"].invoke

    puts "\nDone\n"

    puts "#{saved_records.size} records were saved\n"
    puts "#{unsaved_records.size} records could not be saved\n"
    puts "#{file_missing_records.size} records referenced files that could not be located\n"
    puts "#{skipped_records.size} records were skipped because they already have attachments\n"

    if unsaved_records.present?
      puts 'Unsaved records report the following errors:'
      unsaved_records.each do |record|
        Paperclip::Task.log_error("errors while processing #{klass} ID #{record.id}:")
        Paperclip::Task.log_error(" " + record.errors.full_messages.join("\n ") + "\n")
      end
    end
  end
end
