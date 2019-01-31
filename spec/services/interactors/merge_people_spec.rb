require 'rails_helper'
include Interactors::Errors

RSpec.describe Interactors::MergePeople do
  describe '.perform!' do
    let(:response) { Interactors::MergePeople.perform!(survivor, target) }
    let!(:survivor) { people(:settest_weatest) }
    let!(:target) { people(:cratest_wiltest) }
    let(:survivor_efforts) { survivor.efforts }
    let(:target_efforts) { target.efforts }

    it 'assigns efforts associated with the target to the survivor' do
      expect(target.efforts.size).to eq(1)
      expect(survivor.efforts.size).to eq(1)
      response_efforts = response.resources[:survivor].efforts
      survivor.reload
      expect(survivor.efforts.size).to eq(2)
      expect(response_efforts).to match_array(survivor.efforts)
    end

    it 'assigns the attributes of the target to the survivor' do
      modified_survivor = response.resources[:survivor]
      [:birthdate, :country_code, :state_code, :city].each do |attribute|
        expect(modified_survivor[attribute]).to eq(target[attribute])
      end
    end

    it 'retains the survivor and destroys the target' do
      expect { response }.to change { Person.count }.by(-1)
      expect(Person.find_by(id: survivor.id)).to be_present
      expect(Person.find_by(id: target.id)).to be_nil
    end
  end
end
