desc 'Convert url references to paperclip attachments'
task :urls_to_paperclip, [:model_name, :url_field, :attachment_field] => :environment do |_, args|
  puts "Starting task"

  model_name = args[:model_name]
  url_field = args[:url_field]
  attachment_field = args[:attachment_field]
  attachment_file_name_field = "#{attachment_field}_file_name"

  klass = model_name.classify.constantize
  records = klass.where.not(url_field => nil)

  file_missing_count = 0
  unsaved_record_count = 0
  saved_record_count = 0

  puts "#{records.size} records found needing conversion"

  records.each do |record|
    url = record.send(url_field)
    file_name = url.split('/').last
    file = FileStore.get(url)

    if file
      record.assign_attributes(attachment_field => file, attachment_file_name_field => file_name)
      if record.save
        print '.'
        saved_record_count += 1
      else
        print 'X'
        unsaved_record_count += 1
      end
    else
      print '-'
      file_missing_count += 1
    end
  end

  puts "\nGenerating thumbnails"

  ENV['CLASS'] = "#{klass}"
  Rake::Task["paperclip:refresh:thumbnails"].invoke

  puts "\nDone"

  puts "\n#{saved_record_count} records were saved\n"
  puts "#{unsaved_record_count} records could not be saved\n"
  puts "#{file_missing_count} records referenced files that could not be located\n"
end
