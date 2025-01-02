class Lotteries::Calculations::Base < ApplicationRecord
  include PgSearch::Model

  self.abstract_class = true

  enum gender: {
    male: 0,
    female: 1,
    nonbinary: 2,
  }

  pg_search_scope :person_search,
                  associated_against: {
                    person: [:first_name, :last_name, :city, :state_name, :country_name]
                  }

  belongs_to :organization
  belongs_to :person

  delegate :bio, :flexible_geolocation, :name, to: :person

  def self.search_default_none(param)
    return none unless param && param.size > 2

    person_search(param)
  end
end
