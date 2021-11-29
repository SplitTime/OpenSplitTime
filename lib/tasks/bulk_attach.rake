namespace :bulk_attach do
  desc 'For a collection of resources, attach files in bulk'
  task :resources, [:model, :resource_ids, :attachment_attribute, :path_prefix, :key_attribute, :path_postfix] => :environment do |_, args|
    start_time = Time.current
    abort "No model specified" unless args.model
    abort "No resource_ids specified" unless args.resource_ids
    abort "No attachment_attribute specified" unless args.attachment_attribute
    abort "No path_prefix specified" unless args.path_prefix
    abort "No key_attribute specified" unless args.key_attribute
    abort "No path_postfix specified" unless args.path_postfix

    attachment_attribute = args.attachment_attribute
    model = args.model.to_s.classify.constantize
    resource_ids = args.resource_ids.split(',')
    resources = model.where(id: resource_ids)
    puts "Updating #{resources.size} records"

    resources.each do |resource|
      current_resource = "#{resource.to_param}"
      url = args.path_prefix + resource.send(args.key_attribute).to_s + args.path_postfix

      begin
        puts "Assigning #{url} to #{current_resource}"

        filename = File.basename(URI.parse(url).path)
        file = URI.open(url)

        if resource.send(attachment_attribute).attach(io: file, filename: filename)
          puts "Attached #{attachment_attribute} for #{current_resource}"
        else
          puts "Could not attach #{attachment_attribute} for #{current_resource}"
          puts resource.errors.full_messages
          puts resource.attributes
        end
      rescue OpenURI::HTTPError => e
        puts "Error opening #{filename}"
        puts e
        next
      end
    end

    elapsed_time = Time.current - start_time
    puts "\nFinished bulk_attach:filenames in #{elapsed_time} seconds"
  end

  desc 'For an event_group, attach photos to efforts'
  task :photos_to_efforts, [:event_group_id, :path_prefix, :path_postfix] => :environment do |_, args|
    event_group_id = args.event_group_id

    begin
      puts "Searching for event group id: #{event_group_id}"
      event_group = EventGroup.friendly.find(event_group_id)
      puts "Attaching photos for event group: #{event_group.to_param}"
    rescue ActiveRecord::RecordNotFound
      abort 'Event group was not found'
    end

    events = Event.where(event_group_id: event_group.id)
    efforts = Effort.where(event_id: events)

    puts "Found #{efforts.size} efforts"

    model = 'efforts'
    resource_ids = efforts.ids.join(',')
    attachment_attribute = 'photo'
    path_prefix = args.path_prefix
    key_attribute = 'bib_number'
    path_postfix = args.path_postfix

    Rake::Task['bulk_attach:resources'].invoke(model, resource_ids, attachment_attribute, path_prefix, key_attribute, path_postfix)
  end
end
