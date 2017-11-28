namespace :pull_event do
  desc 'Pulls and imports full event data including effort information from my.raceresult.com into an event'
  task :race_result_full, [:event_id, :rr_event_id, :rr_contest_id, :rr_format] => :environment do |_, args|
    source_uri = ETL::Helpers::RaceResultUriBuilder
                     .new(args[:rr_event_id], args[:rr_contest_id], args[:rr_format]).full_uri
    Rake::Task['pull_event:from_uri'].invoke(args[:event_id], source_uri, :race_result_full)
  end


  desc 'Pulls and imports time data from my.raceresult.com into an event having existing efforts'
  task :race_result_times, [:event_id, :rr_event_id, :rr_contest_id, :rr_format] => :environment do |_, args|
    source_uri = ETL::Helpers::RaceResultUriBuilder
                     .new(args[:rr_event_id], args[:rr_contest_id], args[:rr_format]).full_uri
    Rake::Task['pull_event:from_uri'].invoke(args[:event_id], source_uri, :race_result_times)
  end


  desc 'Pulls and imports effort and time data from adilas.biz/bear100 into an event'
  task :adilas_bear_times, [:event_id, :begin_adilas_id, :end_adilas_id] => :environment do |_, args|
    (args[:begin_adilas_id]..args[:end_adilas_id]).each do |adilas_id|
      source_uri = "https://www.adilas.biz/bear100/runner_details.cfm?id=#{adilas_id}"
      Rake::Task['pull_event:from_uri'].invoke(args[:event_id], source_uri, :adilas_bear_times)
      Rake::Task['pull_event:from_uri'].reenable
    end
  end


  desc 'Pulls and imports event data from the given source_uri into an event using a specified format'
  task :from_uri, [:event_id, :source_uri, :format] => :environment do |_, args|
    start_time = Time.current

    # Get an authenticated token from OpenSplitTime

    rake_username = ENV['RAKE_USERNAME']
    rake_password = ENV['RAKE_PASSWORD']
    abort('Aborted: Username and/or password not provided') unless rake_username && rake_password
    puts 'Located username and password'

    puts 'Authenticating with OpenSplitTime'
    auth_url = "#{ENV['BASE_URI']}/api/v1/auth"
    auth_params = {user: {email: rake_username, password: rake_password}}
    auth_headers = {accept: 'application/json'}
    puts "Requesting authentication for #{auth_params[:user][:email]}"
    begin
      auth_response = RestClient.post(auth_url, auth_params, auth_headers)
    rescue RestClient::ExceptionWithResponse => e
      auth_response = e.response
    end

    auth_response_body = auth_response.body.presence || '{}'
    parsed_response = JSON.parse(auth_response_body)
    auth_token = parsed_response['token']
    unless auth_token
      abort('Aborted: Authentication failed with status ' + "#{auth_response.code}\n" + "#{parsed_response['errors'].join("\n")}")
    end
    puts 'Authenticated'

    # Locate the requested event

    begin
      event = Event.friendly.find(args[:event_id])
    rescue ActiveRecord::RecordNotFound
      abort("Aborted: Event id #{args[:event_id]} not found") unless event
    end
    puts "Located event: #{event.name}"

    # Fetch source data from provided URI

    source_uri = args[:source_uri]
    puts "Fetching data from #{source_uri}"

    begin
      source_response = RestClient.get(source_uri)
    rescue RestClient::ExceptionWithResponse => e
      source_response = e.response
    end

    unless source_response.code == 200
      abort("Aborted: Response failed from #{source_uri} with status #{source_response.code}\nHeaders: #{source_response.headers}\nBody: #{source_response.body}")
    end
    puts "Received data from #{source_uri}"

    # Upload source data to OpenSplitTime /import endpoint

    upload_url = "#{ENV['BASE_URI']}/api/v1/events/#{args[:event_id]}/import"
    upload_params = {data: source_response.body, data_format: args[:format]}
    upload_headers = {authorization: auth_token, accept: 'application/json'}
    puts "Uploading data to #{upload_url}"

    begin
      upload_response = RestClient.post(upload_url, upload_params, upload_headers)
    rescue RestClient::ExceptionWithResponse => e
      upload_response = e.response
    end

    upload_response_body = upload_response.body.presence || '{}'
    parsed_upload_response = JSON.parse(upload_response_body)
    elapsed_time = Time.current - start_time

    if upload_response.code == 201
      puts "\nFinished pull_event:from_uri for event: #{event.name} from #{source_uri} in #{elapsed_time} seconds\n"
    else
      puts "\nERROR during pull_event:from_uri for event: #{event.name} from #{source_uri} in #{elapsed_time} seconds\n"
      puts parsed_upload_response['errors'].join("\n")
    end
  end
end
