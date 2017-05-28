module DataImport
  class Reader

    def initialize(file_path, read_strategy_class)
      @file_path = file_path
      @read_strategy_class = read_strategy_class
    end

    def read_strategy
      @read_strategy ||= read_strategy_class.new(file_path)
    end

    delegate :read_file, :errors, to: :read_strategy

    private

    attr_reader :file_path, :read_strategy_class
  end
end
