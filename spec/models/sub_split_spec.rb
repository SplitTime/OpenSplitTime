require 'rails_helper'

# t.integer "bitkey",       null: false
# t.string  "kind",       null: false


RSpec.describe SubSplit, type: :model do
  it 'should be valid with a bitkey and a kind' do
    sub_split = SubSplit.new(bitkey: 1, kind: 'In')

    expect(SubSplit.all.count).to(equal(0))
    expect(sub_split).to be_valid
  end

  it 'should be invalid without a bitkey' do
    sub_split = SubSplit.new(bitkey: nil, kind: 'In')
    expect(sub_split).not_to be_valid
  end

  it 'should be invalid without a kind' do
    sub_split = SubSplit.new(bitkey: 1, kind: nil)
    expect(sub_split).not_to be_valid
  end

  it 'should be invalid with a duplicate bitkey' do
    SubSplit.create!(bitkey: 1, kind: 'In')
    sub_split = SubSplit.new(bitkey: 1, kind: 'Out')
    expect(sub_split).not_to be_valid
  end

  it 'should be invalid if bitkey shares any bit with an existing bitkey' do
    SubSplit.create!(bitkey: 1, kind: 'In')
    SubSplit.create!(bitkey: 2, kind: 'Out')
    sub_split1 = SubSplit.new(bitkey: 4, kind: 'Up')
    sub_split2 = SubSplit.new(bitkey: 5, kind: 'Down')
    sub_split3 = SubSplit.new(bitkey: 6, kind: 'Strange')
    expect(sub_split1).to be_valid
    expect(sub_split2).not_to be_valid
    expect(sub_split3).not_to be_valid
  end

  it 'should be invalid if bitkey uses more than one bit' do
    SubSplit.create!(bitkey: 1, kind: 'In')
    sub_split1 = SubSplit.new(bitkey: 6, kind: 'Out')
    expect(sub_split1).not_to be_valid
  end

end
