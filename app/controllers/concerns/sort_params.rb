module SortParams
  def self.prepare(sort_params)
    fields = sort_params.to_s.split(',')
    convert_to_ordered_hash(fields)
  end

  def self.convert_to_ordered_hash(fields)
    fields.each_with_object({}) do |field, hash|
      if field.start_with?('-')
        hash[field[1..-1]] = :desc
      else
        hash[field] = :asc
      end
    end
  end
end
