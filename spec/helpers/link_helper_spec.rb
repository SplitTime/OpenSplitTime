require 'rails_helper'

RSpec.describe LinkHelper do
  before do
    controller.params[:sort] = {name: :asc, age: :desc}
  end

  describe '.reversed_sort_param' do
    context 'when the field value is :asc' do
      it 'returns the field name in string format with a minus sign' do
        field = :name
        expected = '-name'
        expect(helper.reversed_sort_param(field)).to eq(expected)
      end
    end

    context 'when the field value is :desc' do
      it 'returns the field name in string format' do
        field = :age
        expected = 'age'
        expect(helper.reversed_sort_param(field)).to eq(expected)
      end
    end

    context 'when the field value does not exist and default is set to :asc' do
      it 'returns the field name in string format' do
        field = :height
        default = :asc
        expected = 'height'
        expect(helper.reversed_sort_param(field, default)).to eq(expected)
      end
    end

    context 'when the field value does not exist and default is set to :desc' do
      it 'returns the field name in string format with a minus sign' do
        field = :height
        default = :desc
        expected = '-height'
        expect(helper.reversed_sort_param(field, default)).to eq(expected)
      end
    end

    it 'works properly if passed a string' do
      field = 'name'
      expected = '-name'
      expect(helper.reversed_sort_param(field)).to eq(expected)
    end
  end

  describe '.toggled_sort_param' do
    context 'when the sort param includes field_1' do
      before do
        controller.params[:sort] = {first_name: :asc}
      end

      it 'returns field_2 as a string' do
        field_1 = 'first_name'
        field_2 = 'last_name'
        expected = field_2
        expect(helper.toggled_sort_param(field_1, field_2)).to eq(expected)
      end
    end

    context 'when the sort param includes field_2' do
      before do
        controller.params[:sort] = {last_name: :asc}
      end

      it 'returns field_1 as a string' do
        field_1 = 'first_name'
        field_2 = 'last_name'
        expected = field_1
        expect(helper.toggled_sort_param(field_1, field_2)).to eq(expected)
      end
    end

    context 'when the sort param includes both field_1 and field_2' do
      before do
        controller.params[:sort] = {last_name: :asc, first_name: :asc}
      end

      it 'returns field_2 as a string' do
        field_1 = 'first_name'
        field_2 = 'last_name'
        expected = field_2
        expect(helper.toggled_sort_param(field_1, field_2)).to eq(expected)
      end
    end

    context 'when the sort param includes neither field_1 nor field_2' do
      before do
        controller.params[:sort] = {id: :asc}
      end

      it 'returns field_1 as a string' do
        field_1 = 'first_name'
        field_2 = 'last_name'
        expected = field_1
        expect(helper.toggled_sort_param(field_1, field_2)).to eq(expected)
      end
    end
  end
end
