# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResultsTemplate, type: :model do
  it_behaves_like 'auditable'

  subject(:results_template) { build(:results_template) }

  describe '#initialize' do
    it 'saves a new record to the database' do
      expect(results_template).to be_valid
      expect { results_template.save }.to change { ResultsTemplate.count }.by (1)
    end
  end
end
