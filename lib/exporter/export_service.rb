# frozen_string_literal: true

module Exporter
  class ExportService
    BATCH_SIZE = 50

    def initialize(resource_class, resources, export_attributes)
      @resource_class = resource_class
      @resources = resources
      @export_attributes = export_attributes
    end

    def csv_to_file(open_file)
      open_file.write(export_attributes.map { |attr| attr.to_s.humanize }.join(","))

      page = 0

      loop do
        batch = resource_subquery.limit(BATCH_SIZE).offset(page * BATCH_SIZE)

        batch.each do |record|
          open_file.write "\n"
          open_file.write serialized_record(record)
        end

        break if batch.empty?
        page += 1
      end
    end

    private

    attr_reader :resource_class, :resources, :export_attributes

    def resource_subquery
      resource_class.from(resources, resource_class.table_name)
    end

    def serialized_record(record)
      export_attributes.map { |attribute| record.public_send(attribute) }.join(",")
    end
  end
end
