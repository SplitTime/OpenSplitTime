module DataImport
  class Reader

    def initialize(file_path, strategy)
      @file_path = file_path
      @strategy = strategy
    end

    def read_file
      strategy.new(file_path).read_file
    end

    private

    attr_reader :file_path, :strategy
  end
end
