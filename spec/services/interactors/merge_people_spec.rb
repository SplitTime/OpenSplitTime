require 'rails_helper'
include Interactors::Errors

RSpec.describe Interactors::MergePeople do
  describe '.perform!' do
    let(:response) { Interactors::MergePeople.perform!(survivor, target) }
    let!(:survivor) { create(:person, efforts: survivor_efforts) }
    let!(:target) { create(:person, :with_birthdate, :with_geo_attributes, efforts: target_efforts) }
    let(:survivor_efforts) { create_list(:effort, 2) }
    let(:target_efforts) { create_list(:effort, 2) }

    it 'assigns efforts associated with the target to the survivor' do
      efforts = response.resources[:survivor].efforts
      expect(efforts.count).to eq(4)
      Effort.all.each do |effort|
        expect(efforts).to include(effort)
      end
    end

    it 'assigns the attributes of the target to the survivor' do
      modified_survivor = response.resources[:survivor]
      [:birthdate, :country_code, :state_code, :city].each do |attribute|
        expect(modified_survivor[attribute]).to eq(target[attribute])
      end
    end

    it 'retains the survivor and destroys the target' do
      expect(Person.count).to eq(2)
      modified_survivor = response.resources[:survivor]
      expect(Person.count).to eq(1)
      expect(Person.find_by(id: survivor.id)).to eq(modified_survivor)
      expect(Person.find_by(id: target.id)).to be_nil
    end
  end
end
