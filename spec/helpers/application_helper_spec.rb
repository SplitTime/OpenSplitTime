require 'rails_helper'

describe ApplicationHelper do
  it 'generates time components from seconds and an hms code' do
    expect(helper.time_components(3630, 'hms')).to eq([1, 0, 30])
    expect(helper.time_components(3630, 'hm')).to eq([1, 0])
    expect(helper.time_components(3630, 'ms')).to eq([0, 30])
  end

end