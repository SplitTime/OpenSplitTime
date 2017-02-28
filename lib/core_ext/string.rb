class String
  def numeric?
    true if Float(self) rescue false
  end

  def numericize
     self.gsub(/[^\d\.]/, '').to_f
  end

  def to_boolean
    # For Rails 5 upgrade, the scope will change to ActiveModel::Type::Boolean
    ActiveRecord::Type::Boolean.new.type_cast_from_user(self)
  end
  alias_method :to_bool, :to_boolean
end