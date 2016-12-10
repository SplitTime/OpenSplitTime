module GuaranteedFindable
  extend ActiveSupport::Concern

  # Requires .null_record class method on incorporating class

  module ClassMethods
    def find_guaranteed(args)
      find_by(args) || null_record
    end
  end
end