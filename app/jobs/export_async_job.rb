# frozen_string_literal: true

require "fileutils"

class ExportAsyncJob < ApplicationJob
  def perform(user_id, controller_name, resource_class_name, sql_string)
    ::ActiveRecord::Base.logger = nil

    current_user = ::User.find(user_id)

    resource_class = resource_class_name.constantize

    # Get a new ActiveRecord::Relation from the sql_string
    resources = resource_class.from("(#{sql_string}) #{resource_class_name.underscore.pluralize}")

    # Make a /tmp directory if one does not already exist
    ::FileUtils.mkdir_p(Rails.root.join("tmp"))

    # filename is in the form of "course_group_best_efforts-1668309553.csv"
    filename = "#{controller_name.underscore.pluralize}-#{Time.current.to_i}.csv"
    full_path = ::File.join(Rails.root.join("tmp"), filename)
    file = ::File.open(full_path, "w")
    # ::ExporterService.new(resource_class, resources).csv_to_file(file)
    file.write "This is another test, just putting some things here, to see if this works at all a second time."
    file.close

    current_user.reports.attach(:io => ::File.open(full_path), :filename => filename, :content_type => "text/csv")
  end
end
