# frozen_string_literal: true

class BaseParameters
  def self.permitted
    []
  end

  def self.permitted_query
    permitted
  end

  def self.strong_params(params)
    params.require(class_name).permit(*permitted)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: permitted)
  end

  def self.mapping
    {}
  end

  def self.csv_export_attributes
    []
  end

  def self.unique_key
    []
  end

  def self.class_name
    self.to_s.sub('Parameters', '').underscore
  end
end
