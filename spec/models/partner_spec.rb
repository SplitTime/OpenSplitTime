require "rails_helper"

RSpec.describe Partner, type: :model do
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:banner_link).collapse_spaces }
end
