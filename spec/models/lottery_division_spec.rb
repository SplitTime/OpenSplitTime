# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotteryDivision, type: :model do
  it { is_expected.to strip_attribute(:name) }
  it { is_expected.to capitalize_attribute(:name) }
end
