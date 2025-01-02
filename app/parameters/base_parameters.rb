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

  def self.mapping
    {}
  end

  def self.csv_export_attributes
    []
  end

  def self.unique_key
    []
  end
end
