# Reset User.current between examples. ApplicationController assigns
# User.current = current_user on every request, so controller/request specs
# that log in leave that thread-local pointing at a now-rolled-back user when
# the example ends. Auditable's before_validation then sets created_by from
# the stale User.current.id, causing FK violations in subsequent examples.
RSpec.configure do |config|
  config.before { User.current = nil }
end
