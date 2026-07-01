require "rails_helper"

RSpec.describe RandomEffortAttributes do
  subject(:attributes) { described_class.generate }

  it "returns a fabricated, valid identity without a bib number" do
    expect(attributes[:first_name]).to be_present
    expect(attributes[:last_name]).to be_present
    expect(attributes[:gender]).to be_in(%w[male female])
    expect(attributes[:country_code]).to eq("US")
    expect(Carmen::Country.coded("US").subregions.map(&:code)).to include(attributes[:state_code])
    expect(attributes).not_to have_key(:bib_number)
  end
end
