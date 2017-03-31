module IncludeParams
  def self.prepare(include_params)
    include_params.to_s.underscore
  end
end
