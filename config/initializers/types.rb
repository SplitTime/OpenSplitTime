require "type/integer_array_from_string"

ActiveModel::Type.register(:integer_array_from_string, ::Type::IntegerArrayFromString)
ActiveRecord::Type.register(:integer_array_from_string, ::Type::IntegerArrayFromString)
