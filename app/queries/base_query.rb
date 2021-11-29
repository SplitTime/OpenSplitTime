# frozen_string_literal: true

class BaseQuery
  def self.sql_safe_integer_list(array)
    array.flatten.compact.map(&:to_i).join(',')
  end

  def self.sql_select_from_string(column_names_string, allowed, default)
    column_names_array = (column_names_string || '').split(',').map { |e| e.strip.to_sym }
    (column_names_array & allowed).join(', ').presence || default
  end

  def self.sql_order_from_hash(sort, allowed, default)
    sort_fields = (sort || {}).symbolize_keys
    allowed_fields = allowed.map(&:to_sym).to_set
    filtered_fields = sort_fields.select { |field, _| allowed_fields.include?(field) } # Don't use #slice here as it may reorder the sort_fields
    filtered_string = filtered_fields.map { |field, direction| "#{field} #{direction}"}.join(', ')
    filtered_string.presence || default.to_s
  end

  # Converts an ActiveRecord-style hash to a SQL string for a WHERE clause
  # {efforts: {event_id: 12, first_name: 'Bill'}} becomes
  # "efforts.event_id = 12 and efforts.first_name = 'Bill'"

  def self.where_string_from_hash(hash)
    hash.map do |table, criteria|
      criteria.map do |field, value|
        new_value, operator = case
                              when value.is_a?(String)
                                [sql_quotify(value), '=']
                              when value.is_a?(Array)
                                ["(#{value.map { |e| sql_quotify(e) }.join(', ')})", 'in']
                              else
                                [value, '=']
                              end
        "#{table}.#{field} #{operator} #{new_value}"
      end.join(' and ')
    end.join(' and ')
  end

  def self.sql_quotify(value)
    value.is_a?(String) ? "'#{value}'" : value
  end

  def self.reset_database_timezone
    ActiveRecord::Base.connection.execute("set timezone='UTC'")
  end
end
