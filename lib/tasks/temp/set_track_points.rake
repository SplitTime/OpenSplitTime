# This is a temporary rake task that should be deleted
# once it has been run in all environments.

require "active_record"
require "active_record/errors"

namespace :temp do
  desc "sets track points for all courses"
  task set_track_points: :environment do
    Rails.application.eager_load!

    ::Course.find_each do |course|
      identifier = "#{course.name} (#{course.id})"
      puts "Setting track points for #{identifier}"
      result = ::Interactors::SetTrackPoints.perform!(course)

      if result.errors.present?
        puts "Could not set track points for #{identifier}"
        pp result.errors
      end
    end

    puts "Finished updating track points for all courses"
  end
end
