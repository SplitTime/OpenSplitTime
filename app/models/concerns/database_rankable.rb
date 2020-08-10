# frozen_string_literal: true

module DatabaseRankable
  extend ActiveSupport::Concern

  included do
    scope :with_overall_and_gender_rank, -> (*attributes) do
      raise ArgumentError, "One or more ranking attributes must be provided" unless attributes.present?

      order_string = attributes.join(", ")
      select("*, row_number() over (order by #{order_string}) as overall_rank, row_number() over (partition by gender order by #{order_string}) as gender_rank")
    end
  end
end
