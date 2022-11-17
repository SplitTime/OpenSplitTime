# frozen_string_literal: true

require "fileutils"

module Exporter
  class AsyncExporter
    def self.export!(export_job)
      new(export_job).export!
    end

    attr_reader :errors

    def initialize(export_job)
      @export_job = export_job
      @errors = []
      validate_setup
    end

    def export!
      export_job.start!
      export_file
      set_finish_attributes
    end

    private

    attr_reader :export_job
    attr_writer :errors

    delegate :file, :controller_name, :resource_class_name, :sql_string, to: :export_job

    def export_file
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

      export_job.file.attach(:io => ::File.open(full_path), :filename => filename, :content_type => "text/csv")
    end

    def set_finish_attributes
      if errors.empty?
        export_job.update(status: :finished)
      else
        export_job.update(status: :failed, error_message: errors.to_json)
      end
    end

    def validate_setup
      # errors << missing_parent_error(parent_type) unless parent.present?
    end
  end
end