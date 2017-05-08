class BaseParameters

  def self.permitted
    []
  end

  def self.permitted_query
    permitted
  end

  def self.strong_params(class_name, params)
    params.require(class_name).permit(*permitted)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: permitted)
  end

  def self.key_mapping
    {}
  end
end
