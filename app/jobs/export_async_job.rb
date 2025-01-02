class ExportAsyncJob < ApplicationJob
  # def perform(user_id, controller_name, resource_class_name, sql_string)
  def perform(export_job_id)
    export_job = ::ExportJob.find(export_job_id)
    ::Exporter::AsyncExporter.export!(export_job)
  end
end
