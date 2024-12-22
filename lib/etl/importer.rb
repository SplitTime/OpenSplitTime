# frozen_string_literal: true

module ETL
  class Importer
    include ETL::Errors

    REPORT_ARRAYS = [:saved_records, :invalid_records, :destroyed_records, :ignored_records, :errors].freeze
    attr_reader(*REPORT_ARRAYS)

    def initialize(source_data, format, options = {})
      @source_data = source_data
      @format = format
      @options = options
      @saved_records = []
      @invalid_records = []
      @destroyed_records = []
      @ignored_records = []
      @errors = []
    end

    def import
      case format
      when :race_result_full
        import_with(source_data, Extractors::RaceResultStrategy, Transformers::RaceResultSplitTimesStrategy, Loaders::InsertStrategy, { delete_blank_times: true }.merge(options))
      when :race_result_entrants
        import_with(source_data, Extractors::RaceResultStrategy, Transformers::RaceResultEntrantsStrategy, Loaders::UpsertStrategy, { delete_blank_times: false, unique_key: [:event_id, :bib_number] }.merge(options))
      when :race_result_api_times
        import_with(source_data, Extractors::RaceResultApiStrategy, Transformers::RaceResultApiSplitTimesStrategy, Loaders::SplitTimeUpsertStrategy, { delete_blank_times: true }.merge(options))
      when :adilas_bear_times
        import_with(source_data, Extractors::AdilasBearHTMLStrategy, Transformers::AdilasBearStrategy, Loaders::InsertStrategy, options)
      when :adilas_bear_times_update
        import_with(source_data, Extractors::AdilasBearHTMLStrategy, Transformers::AdilasBearStrategy, Loaders::SplitTimeUpsertStrategy, options)
      when :its_your_race_times
        import_with(source_data, Extractors::ItsYourRaceHTMLStrategy, Transformers::ElapsedIncrementalAidStrategy, Loaders::InsertStrategy, options)
      when :csv_splits
        import_with(source_data, Extractors::CsvFileStrategy, Transformers::GenericResourcesStrategy, Loaders::UpsertStrategy, { model: :split }.merge(default_unique_key(:split)).merge(options))
      when :csv_raw_times
        import_with(source_data, Extractors::CsvFileStrategy, Transformers::GenericResourcesStrategy, Loaders::UpsertStrategy, { model: :raw_time }.merge(default_unique_key(:raw_time)).merge(options))
      when :csv_efforts
        import_with(source_data, Extractors::CsvFileStrategy, Transformers::GenericResourcesStrategy, Loaders::UpsertStrategy, { model: :effort }.merge(default_unique_key(:effort)).merge(options))
      when :jsonapi_batch
        import_with(source_data, Extractors::PassThroughStrategy, Transformers::JsonapiBatchStrategy, Loaders::UpsertStrategy, options)
      else
        errors << format_not_recognized_error(format)
      end
    end

    def strict?
      options[:strict]
    end

    private

    attr_reader :source_data, :format, :options
    attr_writer(*REPORT_ARRAYS)

    def import_with(source_data, extract_strategy, transform_strategy, load_strategy, options)
      extractor = ETL::Extractor.new(source_data, extract_strategy, options)
      extracted_data = extractor.extract
      self.errors += extractor.errors and return if extractor.errors.present?

      transformer = ETL::Transformer.new(extracted_data, transform_strategy, options)
      proto_records = transformer.transform
      self.errors += transformer.errors and return if transformer.errors.present?

      proto_record_groups = strict? ? [proto_records] : proto_records.map { |record| [record] }
      proto_record_groups.each do |proto_record_group|
        loader = ETL::Loader.new(proto_record_group, load_strategy, options)
        loader.load_records
        REPORT_ARRAYS.each do |report_array|
          loader.send(report_array).each { |report_element| send(report_array) << report_element }
        end
      end
    end

    def default_unique_key(model_name)
      { unique_key: params_class(model_name).unique_key }
    end

    def params_class(model_name)
      "#{model_name.to_s.classify}Parameters".constantize
    end
  end
end
