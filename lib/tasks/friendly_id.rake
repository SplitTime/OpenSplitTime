namespace :friendly_id do
  desc 'For a given model, adds all friendly_id slugs to the friendly_id_slugs table'
  task :update_slugs, [:model] => :environment do |_, args|
    start_time = Time.current
    abort "No model specified" unless args.model

    model = args.model.to_s.classify.constantize
    puts "Updating #{model.count} #{model.to_s.pluralize}"
    model.find_each do |resource|
      current_resource = "#{model} #{resource.slug}"

      if resource.update(slug: resource.slug)
        puts "Updated slug for #{current_resource}"
      else
        abort "Could not update #{current_resource}"
      end
    end

    elapsed_time = Time.current - start_time
    puts "\nFinished friendly_id:update_slugs for model #{model} in #{elapsed_time} seconds"
  end

  desc 'For all friendly_id models, adds friendly_id slugs to the friendly_id_slugs table'
  task :update_all_slugs => :environment do
    start_time = Time.current

    [:event, :event_group, :course, :split, :person, :effort, :organization, :user].each do |model_name|
      Rake::Task["friendly_id:update_slugs"].invoke(model_name)
      Rake::Task["friendly_id:update_slugs"].reenable
    end

    elapsed_time = Time.current - start_time
    puts "\nFinished friendly_id:update_slugs for all models in #{elapsed_time} seconds"
  end
end
