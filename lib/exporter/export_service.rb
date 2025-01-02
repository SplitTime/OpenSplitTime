require "csv"

module Exporter
  class ExportService
    BATCH_SIZE = 500

    def initialize(resource_class, resources, export_attributes)
      @resource_class = resource_class
      @resources = resources
      @export_attributes = export_attributes
    end

    def csv_to_file(open_file)
      open_file.write csv_header

      # Remember that find_each and find_in_batches will ignore ordering.
      # This algorithm preserves ordering by using LIMIT and OFFSET instead,
      # which should be acceptable for exports of up to 100,000 records or so.
      page = 0

      loop do
        batch = resource_subquery.limit(BATCH_SIZE).offset(page * BATCH_SIZE)

        batch.each { |record| open_file.write serialized_record(record) }

        break if batch.empty?
        page += 1
      end
    end

    private

    attr_reader :resource_class, :resources, :export_attributes

    def csv_header
      humanized_attributes = export_attributes.map { |attribute| attribute.to_s.humanize }
      ::CSV.generate_line(humanized_attributes)
    end

    def resource_subquery
      resource_class.from(resources, resource_class.table_name)
    end

    def serialized_record(record)
      attributes = export_attributes.map { |attribute| record.public_send(attribute) }
      ::CSV.generate_line(attributes)
    end
  end
end
