desc "This task is called by the Heroku scheduler add-on"
task :scheduled_sitemap_upload => :environment do
  Rake::Task["sitemap:create_upload_and_ping"].invoke
end