# frozen_string_literal: true

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
      attributes = args[:attributes]
      includes = args[:includes] || {}
      where(attributes).includes(includes).first || null_record
    end
  end
end
