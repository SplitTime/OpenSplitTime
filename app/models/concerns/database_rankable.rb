module DatabaseRankable
  extend ActiveSupport::Concern

  included do
    scope :with_overall_and_gender_rank, lambda { |*attributes|
      raise ArgumentError, "One or more ranking attributes must be provided" unless attributes.present?

      order_string = attributes.join(", ")
      select("*, rank() over (order by #{order_string}) as overall_rank, rank() over (partition by gender order by #{order_string}) as gender_rank")
    }
  end
end
