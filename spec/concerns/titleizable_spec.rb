# frozen_string_literal: true

require "rails_helper"

class DummyTitleizableClass
  include ::ActiveModel::Attributes
  include ::ActiveModel::Validations
  include ::ActiveModel::Validations::Callbacks
  include ::Titleizable

  attribute :first_name
  attribute :last_name
  attribute :city

  titleize_attributes :first_name, :last_name
  titleize_attribute :city
end

RSpec.describe ::DummyTitleizableClass do
  it_behaves_like "titleizable", :first_name, :last_name, :city
end
