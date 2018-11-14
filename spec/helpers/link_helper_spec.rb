# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LinkHelper do
  let(:presenter) { EventWithEffortsPresenter.new(event: event, params: prepared_params) }
  let(:event) { build_stubbed(:event) }
  let(:prepared_params) { create(:prepared_params, params: params, permitted_query: [:name, :age, :first_name, :last_name]) }

  describe '.reversed_sort_param' do
    context 'when the field value in the presenter.sort_hash is :asc' do
      let(:params) { ActionController::Parameters.new(sort: 'name') }

      it 'returns the field name in string format with a minus sign' do
        field = :name
        expected = '-name'
        expect(helper.reversed_sort_param(presenter, field)).to eq(expected)
      end

      it 'works properly if passed a string' do
        field = 'name'
        expected = '-name'
        expect(helper.reversed_sort_param(presenter, field)).to eq(expected)
      end
    end

    context 'when the field value in the presenter.sort_hash is :desc' do
      let(:params) { ActionController::Parameters.new(sort: '-name') }

      it 'returns the field name in string format' do
        field = :name
        expected = 'name'
        expect(helper.reversed_sort_param(presenter, field)).to eq(expected)
      end
    end

    context 'when the field value does not exist in the presenter.sort_hash and default is set to :asc' do
      let(:params) { ActionController::Parameters.new(sort: 'name') }

      it 'returns the field name in string format' do
        field = :height
        default = :asc
        expected = 'height'
        expect(helper.reversed_sort_param(presenter, field, default)).to eq(expected)
      end
    end

    context 'when the field value does not exist in the presenter.sort_hash and default is set to :desc' do
      let(:params) { ActionController::Parameters.new(sort: 'name') }

      it 'returns the field name in string format with a minus sign' do
        field = :height
        default = :desc
        expected = '-height'
        expect(helper.reversed_sort_param(presenter, field, default)).to eq(expected)
      end
    end
  end

  describe '.toggled_sort_param' do
    context 'when the presenter.sort_hash includes field_1' do
      let(:params) { ActionController::Parameters.new(sort: 'first_name') }

      it 'returns field_2 as a string' do
        field_1 = 'first_name'
        field_2 = 'last_name'
        expected = field_2
        expect(helper.toggled_sort_param(presenter, field_1, field_2)).to eq(expected)
      end
    end

    context 'when the presenter.sort_hash includes field_2' do
      let(:params) { ActionController::Parameters.new(sort: 'last_name') }

      it 'returns field_1 as a string' do
        field_1 = 'first_name'
        field_2 = 'last_name'
        expected = field_1
        expect(helper.toggled_sort_param(presenter, field_1, field_2)).to eq(expected)
      end
    end

    context 'when the presenter.sort_hash includes both field_1 and field_2' do
      let(:params) { ActionController::Parameters.new(sort: 'first_name,last_name') }

      it 'returns field_2 as a string' do
        field_1 = 'first_name'
        field_2 = 'last_name'
        expected = field_2
        expect(helper.toggled_sort_param(presenter, field_1, field_2)).to eq(expected)
      end
    end

    context 'when the presenter.sort_hash includes neither field_1 nor field_2' do
      let(:params) { ActionController::Parameters.new(sort: '') }

      it 'returns field_1 as a string' do
        field_1 = 'first_name'
        field_2 = 'last_name'
        expected = field_1
        expect(helper.toggled_sort_param(presenter, field_1, field_2)).to eq(expected)
      end
    end
  end
end
