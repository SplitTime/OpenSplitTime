RSpec::Matchers.define :a_hash_approximating do |hash, tolerance|
  match do |actual|
    hash.each do |key, _|
      actual.has_key?(key) && (actual[key] - hash[key]).abs < tolerance
    end
  end
end
