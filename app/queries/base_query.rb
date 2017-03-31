class BaseQuery

  def self.sql_safe_integer_list(array)
    array.flatten.compact.map(&:to_i).join(',')
  end

  def self.sql_select_from_string(column_names, allowed, default)
    (column_names.to_s.split(',') & allowed).join(', ').presence || default
  end

  def self.sql_order_from_hash(sort_fields, allowed, default)
    allowed = allowed.map(&:to_sym)
    filtered_string = sort_fields.to_h.slice(*allowed).map { |field, direction| "#{field} #{direction}"}.join(', ')
    filtered_string.present? ? filtered_string : default
  end
end
