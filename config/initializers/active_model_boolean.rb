# Expand the standard library of boolean string values that return false

%w(False Off n N no NO No).each do |string|
  ActiveModel::Type::Boolean::FALSE_VALUES << string
end
