class PartnerParameters < BaseParameters
  def self.permitted
    [:name, :banner, :banner_link, :weight]
  end
end
