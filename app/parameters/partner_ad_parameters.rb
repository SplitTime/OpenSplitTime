class PartnerAdParameters < BaseParameters

  def self.permitted
    [:id, :event_id, :banner, :link, :weight]
  end
end
