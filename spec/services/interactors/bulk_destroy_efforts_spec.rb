# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Interactors::BulkDestroyEfforts do
  include BitkeyDefinitions

  subject { Interactors::BulkDestroyEfforts.new(efforts) }
  let(:event_group) { event_groups(:sum) }

  describe '#perform!' do
    context 'when efforts are provided having both split times and raw times' do
      let(:efforts) { event_group.efforts.where(bib_number: [777, 999]) }
      let(:split_times) { efforts.flat_map(&:split_times) }

      it 'destroys the efforts and related split_times' do
        expect { subject.perform! }.to change { Effort.count }.by(-2).and change { SplitTime.count }.by(-18)
      end

      it 'nullifies related raw_time records' do
        expect(RawTime.where(split_time: split_times)).to be_present
        expect { subject.perform! }.not_to change { RawTime.count }
        expect(RawTime.where(split_time: split_times)).not_to be_present
      end
    end
  end
end
