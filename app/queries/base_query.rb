# frozen_string_literal: true

class BaseQuery

  def self.sql_safe_integer_list(array)
    array.flatten.compact.map(&:to_i).join(',')
  end

  def self.sql_select_from_string(column_names, allowed, default)
    (column_names.to_s.split(',') & allowed).join(', ').presence || default
  end

  def self.sql_order_from_hash(sort_fields, allowed, default)
    sort_fields = sort_fields&.symbolize_keys || {}
    allowed = allowed.map(&:to_sym).to_set
    filtered_fields = sort_fields.reject { |field, _| allowed.exclude?(field) }
    filtered_string = filtered_fields.map { |field, direction| "#{field} #{direction}"}.join(', ')
    filtered_string.present? ? filtered_string : default
  end
end
