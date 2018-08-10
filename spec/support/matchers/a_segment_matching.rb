RSpec::Matchers.define :a_segment_matching do |segment|
  match { |actual| (actual == segment) }
end
