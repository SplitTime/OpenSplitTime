# frozen_string_literal: true

require 'rails_helper'

# t.bigint "effort_id", null: false
# t.integer "distance", null: false
# t.integer "bitkey", null: false
# t.integer "follower_ids", default: [], array: true
# t.integer "created_by"
# t.integer "updated_by"

RSpec.describe Notification, type: :model do
  it_behaves_like 'auditable'
end
