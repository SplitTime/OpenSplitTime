# frozen_string_literal: true

class OrganizationParameters < BaseParameters

  def self.permitted
    [:id, :slug, :name, :description, :concealed]
  end
end
