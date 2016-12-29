module GuaranteedFindable
  extend ActiveSupport::Concern

  # Requires .null_record class method on incorporating class

  def null_record?
    self == self.class.null_record
  end

  def real_record?
    !null_record?
  end

  def real_presence
    self if real_record?
  end

  module ClassMethods
    def find_guaranteed(args)
      find_by(args) || null_record
    end
  end
end