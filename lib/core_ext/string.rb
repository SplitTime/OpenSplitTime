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

  def self.longest_common_phrase(strings)
    n = strings.min_by { |string| string.split.size }.size
    while n > 0 do
      cons_word_sets = strings.map { |string| string.downcase.split.each_cons(n).to_a }
      matching_words = cons_word_sets.reduce(:&).first
      return matching_words&.join(' ') if matching_words
      n -= 1
    end
  end
end
