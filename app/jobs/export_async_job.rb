# frozen_string_literal: true

require "fileutils"

class ExportAsyncJob < ApplicationJob
  def perform(user_id, controller_name, resource_class_name, sql_string)
    ::ActiveRecord::Base.logger = nil

    current_user = ::User.find(user_id)

    resource_class = resource_class_name.constantize
    params_class = "#{resource_class_name}Parameters".constantize

    # Get a new ActiveRecord::Relation from the sql_string
    resources = resource_class.from("(#{sql_string}) #{resource_class.table_name}")
    export_attributes = params_class.csv_export_attributes

    # Make a /tmp directory if one does not already exist
    ::FileUtils.mkdir_p(Rails.root.join("tmp"))

    # filename is in the form of "course_group_best_efforts-1668309553.csv"
    filename = "#{controller_name.underscore.pluralize}-#{Time.current.to_i}-#{resources.count}.csv"
    full_path = ::File.join(Rails.root.join("tmp"), filename)
    file = ::File.open(full_path, "w")

    ::Exporter::ExportService.new(resource_class, resources, export_attributes).csv_to_file(file)
    file.close

    current_user.exports.attach(:io => ::File.open(full_path), :filename => filename, :content_type => "text/csv")
  end
end
