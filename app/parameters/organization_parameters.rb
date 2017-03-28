class OrganizationParameters < BaseParameters

  def self.permitted
    [:id, :name, :description, :concealed]
  end
end
