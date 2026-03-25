module Docs
  class RaceResultPresenter < Docs::BasePresenter
    def category
      :race_result
    end

    def display_category
      "Using RaceResult with OpenSplitTime"
    end

    def items
      {
        overview: {
          display_topic: "Overview",
          pages: ["Welcome"],
        },
        webhook_setup: {
          display_topic: "Webhook Setup",
          pages: ["Configuration Steps"],
        },
      }
    end
  end
end
