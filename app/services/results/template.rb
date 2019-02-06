# frozen_string_literal: true

module Results
  Template = Struct.new(:name, :method, :podium_size, :categories, :point_system, keyword_init: true)
end
