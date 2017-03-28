module FieldParams
  def self.prepare(field_params)
    field_params&.to_unsafe_hash.to_h
        .map { |resource, fields| {resource => fields.split(',').map { |field| field.underscore.to_sym }} }
        .reduce({}, :merge)
  end
end
