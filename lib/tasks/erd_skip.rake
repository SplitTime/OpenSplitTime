# lib/tasks/erd_skip.rake
if ENV['SKIP_ERD'] == 'true'
  begin
    Rake::Task['erd'].clear
    Rake::Task['erd:generate'].clear
    Rake::Task['erd:load_models'].clear
  rescue
  end

  task :erd do
    puts 'Skipping ERD generation (SKIP_ERD=true)'
  end
  task 'erd:generate' => :erd
  task 'erd:load_models' => :erd
end
