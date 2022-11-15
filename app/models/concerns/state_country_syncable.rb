# frozen_string_literal: true

# This module requires the including model to have four columns:
# state_code, country_code, state_name, and country_name.
# It adds a callback to keep state_name and country_name in sync
# with state_code and country_code.
#
module StateCountrySyncable
  extend ActiveSupport::Concern

  included do
    before_save :sync_state_and_country
  end

  private

  def sync_state_and_country
    return unless will_save_change_to_state_code? || will_save_change_to_country_code?

    sync_state
    sync_country
  end

  def sync_state
    return unless state_code.present? && country_code.present?

    self.state_name = ::Carmen::Country.coded(country_code)&.subregions&.coded(state_code)&.name
  end

  def sync_country
    return unless country_code.present?

    self.country_name = ::Carmen::Country.coded(country_code)&.name
  end
end
