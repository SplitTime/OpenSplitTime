require "rails_helper"

RSpec.describe Race, type: :model do
  it "should have a name" do
    Race.create!(name: 'Slow Mo 100')

    expect(Race.all.count).to(equal(1))
    expect(Race.first.name).to eq('Slow Mo 100')
  end
end