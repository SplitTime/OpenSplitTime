require "rails_helper"

RSpec.describe Notification, type: :model do
  it_behaves_like "auditable"
end
