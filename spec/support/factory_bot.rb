RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

FactoryBot.use_parent_strategy = false
