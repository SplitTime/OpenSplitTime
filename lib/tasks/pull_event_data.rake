namespace :pull_event do
  desc 'Pulls and imports full event data including effort information from my.raceresult.com into an event'
  task :race_result_full, [:event_id, :rr_event_id, :rr_contest_id, :rr_format] => :environment do |_, args|
    source_uri = DataImport::Helpers::RaceResultUriBuilder
                     .new(args[:rr_event_id], args[:rr_contest_id], args[:rr_format]).full_uri
    Rake::Task['pull_event:from_uri'].invoke(args[:event_id], source_uri, :race_result_full)
  end


  desc 'Pulls and imports time data from my.raceresult.com into an event having existing efforts'
  task :race_result_times, [:event_id, :rr_event_id, :rr_contest_id, :rr_format] => :environment do |_, args|
    source_uri = DataImport::Helpers::RaceResultUriBuilder
                     .new(args[:rr_event_id], args[:rr_contest_id], args[:rr_format]).full_uri
    Rake::Task['pull_event:from_uri'].invoke(args[:event_id], source_uri, :race_result_times)
  end


  desc 'Pulls and imports event data from the given source_uri into an event using a specified format'
  task :from_uri, [:event_id, :source_uri, :format] => :environment do |_, args|
    start_time = Time.current

    rake_username = ENV['RAKE_USERNAME']
    rake_password = ENV['RAKE_PASSWORD']
    abort('Aborted: Username and/or password not provided') unless rake_username && rake_password
    puts 'Located username and password'

    puts 'Authenticating with OpenSplitTime'
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.post('/api/v1/auth', {user: {email: rake_username, password: rake_password}},
                 {accept: 'application/json'})
    puts "Authentication requested with #{session.request.filtered_parameters}"
    response_body = session.response.body.presence || '{}'
    parsed_response = JSON.parse(response_body)
    auth_token = parsed_response['token']
    abort('Aborted: Authentication failed with status ' +
              "#{session.response.status}\n" +
              "Headers: #{session.response.headers}\n" +
              "Body: #{session.response.body}") unless auth_token
    puts 'Authenticated'

    begin
      event = Event.friendly.find(args[:event_id])
    rescue ActiveRecord::RecordNotFound
      abort("Aborted: Event id #{args[:event_id]} not found") unless event
    end
    puts "Located event: #{event.name}"

    source_uri = URI(args[:source_uri])
    puts "Fetching data from #{source_uri}"
    rr_response = Net::HTTP.get(source_uri)
    abort("Aborted: No response received from #{source_uri}") unless rr_response.present?
    puts "Received data from #{source_uri}"

    ost_path = "/api/v1/events/#{args[:event_id]}/import"
    puts "Uploading data to #{ost_path}"
    session.post(ost_path, {data: rr_response, data_format: args[:format]},
                 {authorization: auth_token, accept: 'application/json'})
    puts session.response.body

    elapsed_time = Time.current - start_time
    puts "\nFinished pull_event:from_uri for event: #{event.name} from #{source_uri} in #{elapsed_time} seconds"
  end
end
