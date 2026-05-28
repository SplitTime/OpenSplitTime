RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

FactoryBot.use_parent_strategy = false

# Expose Rails fixture accessors (e.g. `users(:admin_user)`) inside FactoryBot
# dynamic attribute blocks. FactoryBot::SyntaxRunner is the evaluation context
# for those blocks and does not otherwise see the fixture accessors that RSpec
# mixes into example instances.
module FactoryBotFixtureAccessors
  def users(label)
    User.find(ActiveRecord::FixtureSet.identify(label))
  end
end

FactoryBot::SyntaxRunner.include(FactoryBotFixtureAccessors)
