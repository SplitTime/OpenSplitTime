require "type/integer_array_from_string"
require "type/string_array_from_string"

ActiveModel::Type.register(:integer_array_from_string, ::Type::IntegerArrayFromString)
ActiveRecord::Type.register(:integer_array_from_string, ::Type::IntegerArrayFromString)
ActiveModel::Type.register(:string_array_from_string, ::Type::StringArrayFromString)
ActiveRecord::Type.register(:string_array_from_string, ::Type::StringArrayFromString)
