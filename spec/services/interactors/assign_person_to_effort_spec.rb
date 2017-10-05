require 'rails_helper'

RSpec.describe Interactors::AssignPersonToEffort do

  describe '.perform!' do
    let(:person) { build_stubbed(:person) }
    let(:effort) { build_stubbed(:effort) }

    it 'assigns the person.id to effort.person_id' do
      result = Interactors::AssignPersonToEffort.perform!(person, effort)
      expect(effort.person_id).to eq(person.id)
    end
  end
end
