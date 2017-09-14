class String
  def numeric?
    true if Float(self) rescue false
  end

  def numericize
    self.gsub(/[^\d\.]/, '').to_f
  end

  def to_boolean
    ActiveRecord::Type::Boolean.new.cast(self)
  end
  alias_method :to_bool, :to_boolean

  # Tests if string is a valid UUID v4
  def uuid?
    (self =~ /^[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i).present?
  end

  def longest_common_phrase(other)
    n = [size, other&.size || 0].min
    while n > 0 do
      other_words = other.downcase.split.each_cons(n)
      string_words = split.each_cons(n)
      matching_words = string_words.find { |cons_words| other_words.include?(cons_words.map(&:downcase)) }
      return matching_words&.join(' ') if matching_words
      n -= 1
    end
  end
end
