# frozen_string_literal: true

module ETL
  class AsyncImporter
    include ETL::Errors

    def self.import!(import_job)
      new(import_job).import!
    end

    attr_reader :errors

    def initialize(import_job)
      @import_job = import_job
      @errors = []
      @extracted_structs = []
      @custom_options = {}
      validate_setup
    end

    def import!
      import_job.start!
      set_etl_strategies
      extract_data if errors.empty?
      transform_data if errors.empty?
      load_records if errors.empty?
      set_finish_attributes
    end

    private

    attr_reader :import_job
    attr_writer :errors
    attr_accessor :extract_strategy, :transform_strategy, :load_strategy, :custom_options, :extracted_structs, :transformed_protos

    delegate :files, :format, :parent, to: :import_job

    def set_etl_strategies
      case format.to_sym
      when :event_course_splits
        self.extract_strategy = Extractors::CsvFileStrategy
        self.transform_strategy = Transformers::EventCourseSplitsStrategy
        self.load_strategy = Loaders::AsyncInsertStrategy
      when :event_group_entrants
        self.extract_strategy = Extractors::CsvFileStrategy
        self.transform_strategy = Transformers::EventGroupEntrantsStrategy
        self.load_strategy = Loaders::AsyncInsertStrategy
      when :event_entrants_with_military_times
        self.extract_strategy = Extractors::CsvFileStrategy
        self.transform_strategy = Transformers::Async::EffortsWithTimesStrategy
        self.load_strategy = Loaders::AsyncInsertStrategy
        self.custom_options = { time_format: :military }
      when :hardrock_historical_facts
        self.extract_strategy = Extractors::CsvFileStrategy
        self.transform_strategy = Transformers::Async::HardrockHistoricalFactsStrategy
        self.load_strategy = Loaders::AsyncInsertStrategy
      when :lottery_entrants
        self.extract_strategy = Extractors::CsvFileStrategy
        self.transform_strategy = Transformers::LotteryEntrantsStrategy
        self.load_strategy = Loaders::AsyncInsertStrategy
      else
        errors << format_not_recognized_error(format)
      end
    end

    def extract_data
      import_job.extracting!
      files.each do |file|
        import_job.set_elapsed_time!
        extractor = ::ETL::Extractor.new(file, extract_strategy)
        self.extracted_structs += extractor.extract
        self.errors += extractor.errors
        import_job.update(row_count: extracted_structs.size)
      end
    end

    def transform_data
      import_job.transforming!
      import_job.set_elapsed_time!
      options = { parent: parent, import_job: import_job }.merge(custom_options)
      transformer = ::ETL::Transformer.new(extracted_structs, transform_strategy, options)
      self.transformed_protos = transformer.transform
      self.errors += transformer.errors
    end

    def load_records
      import_job.loading!
      import_job.set_elapsed_time!
      options = { import_job: import_job }.merge(custom_options)
      loader = ::ETL::Loader.new(transformed_protos, load_strategy, options)
      loader.load_records
      self.errors += loader.errors
    end

    def set_finish_attributes
      if errors.empty?
        import_job.update(status: :finished)
      else
        import_job.update(status: :failed, error_message: errors.to_json)
      end
    end

    def validate_setup
      errors << missing_parent_error unless parent.present?
    end
  end
end
