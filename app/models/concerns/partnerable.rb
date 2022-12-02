# frozen_string_literal: true

module Partnerable
  extend ActiveSupport::Concern

  included do
    has_many :partners, as: :partnerable
  end

  def pick_partner_with_banner
    partners.with_banners.flat_map { |partner| [partner] * partner.weight }.sample
  end
end
