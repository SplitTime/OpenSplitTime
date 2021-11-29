# frozen_string_literal: true

class PartnerParameters < BaseParameters

  def self.permitted
    [:id, :name, :event_group_id, :banner, :banner_link, :weight]
  end
end
