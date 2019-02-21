class ResultsCategory < ApplicationRecord
  include Auditable

  INF = 1.0/0

  belongs_to :organization, optional: true
  has_many :results_template_categories, dependent: :destroy
  has_many :results_templates, through: :results_template_categories

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :organization
  validate :gender_present?

  attr_accessor :efforts
  attribute :invalid_efforts, :boolean

  def self.invalid_category(attributes = {})
    standard_attributes = {name: 'Invalid Efforts', male: true, female: true, invalid_efforts: true}
    new(standard_attributes.merge(attributes))
  end

  def age_range
    (low_age || 0)..(high_age || INF)
  end

  def all_ages?
    age_range == (0..INF)
  end

  def genders
    %w[male female].select(&method(:send))
  end

  def all_genders?
    male? && female?
  end

  private

  def gender_present?
    unless male? || female?
      errors.add(:base, 'must include male or female entrants')
    end
  end
end
