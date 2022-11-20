# frozen_string_literal: true

module DatabaseRankable
  extend ActiveSupport::Concern

  included do
    scope :with_overall_and_gender_rank, lambda { |*attributes|
      raise ArgumentError, "One or more ranking attributes must be provided" unless attributes.present?

      order_string = attributes.join(", ")
      select("*, rank() over (order by #{order_string}) as overall_rank, rank() over (partition by gender order by #{order_string}) as gender_rank")
    }

    scope :with_overall_gender_and_event_rank, lambda { |*attributes|
      raise ArgumentError, "One or more ranking attributes must be provided" unless attributes.present?

      order_string = attributes.join(", ")
      select("*, rank() over (order by #{order_string}) as overall_rank, rank() over (partition by gender order by #{order_string}) as gender_rank, rank() over (partition by event_id order by #{order_string}) as event_rank")
    }
  end
end
