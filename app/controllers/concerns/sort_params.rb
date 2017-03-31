module SortParams
  def self.prepare(sort_params)
    fields = sort_params.to_s.split(',')
    ordered_fields = convert_to_ordered_hash(fields)
    ordered_fields.symbolize_keys
  end

  def self.convert_to_ordered_hash(fields)
    fields.each_with_object({}) do |field, hash|
      if field.start_with?('-')
        field = field[1..-1]
        hash[field] = :desc
      else
        hash[field] = :asc
      end
    end
  end
end
