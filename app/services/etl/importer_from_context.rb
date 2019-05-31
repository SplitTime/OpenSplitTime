module ETL
  class ImporterFromContext
    def self.build(parent, params, current_user)
      new(parent, params, current_user).build
    end

    def initialize(parent, params, current_user)
      @parent = parent
      @params = params
      @current_user = current_user
    end

    def build
      ETL::Importer.new(data, data_format, options)
    end

    private

    attr_reader :parent, :params, :current_user

    def data
      if params[:file].is_a?(ActionDispatch::Http::UploadedFile)
        params[:file]
      elsif params[:file]
        File.read(params[:file])
      elsif params[:data].is_a?(String)
        JSON.parse(params[:data]).deep_transform_keys(&:underscore)
      else
        params[:data]
      end
    end

    def data_format
      params[:data_format]&.to_sym
    end

    def options
      result = {parent: parent, current_user_id: current_user.id, strict: strict}
      result[:unique_key] = unique_key if unique_key
      result[:split_name] = params[:split_name] if params[:split_name]
      result
    end

    def strict
      params[:load_records] != 'single'
    end

    def unique_key
      params[:unique_key].present? ? (params[:unique_key] + [parent_id_attribute]).uniq : nil
    end

    def parent_id_attribute
      "#{parent.class.name.underscore}_id"
    end
  end
end
