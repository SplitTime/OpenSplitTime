module Docs
  class UserInfoPresenter < Docs::BasePresenter
    def category
      :user_info
    end

    def display_category
      "User Information"
    end

    def items
      {
        lotteries: { display_topic: "Lotteries", pages: ["Managing service requirements"] },
      }
    end
  end
end
