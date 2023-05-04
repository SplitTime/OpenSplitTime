class ResultsCategory < ApplicationRecord
  include Auditable

  INF = 1.0 / 0

  belongs_to :organization, optional: true
  has_many :results_template_categories, dependent: :destroy
  has_many :results_templates, through: :results_template_categories

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :organization
  validate :gender_present?

  attr_accessor :efforts

  attribute :invalid_efforts, :boolean

  # `position` and `fixed_position` are persisted on the results_template_categories
  # table, but can be set here for convenience, e.g., by ResultsTemplate#dup_with_categories
  attribute :position, :integer
  attribute :fixed_position, :boolean

  def self.invalid_category(attributes = {})
    standard_attributes = {name: "Invalid Efforts", male: true, female: true, invalid_efforts: true}
    new(standard_attributes.merge(attributes))
  end

  def fastest_seconds
    return INF unless efforts.present?

    efforts.first.final_elapsed_seconds
  end

  def age_range
    (low_age || 0)..(high_age || INF)
  end

  def all_ages?
    age_range == (0..INF)
  end

  def genders
    %w[male female nonbinary].select(&method(:send))
  end

  def all_genders?
    male? && female? && nonbinary?
  end

  def description
    "#{gender_description} #{age_description}"
  end

  def age_description
    if all_ages?
      "all ages"
    elsif age_range.begin == 0
      "up to #{high_age}"
    elsif age_range.end == INF
      "#{low_age} and up"
    else
      "#{low_age} to #{high_age}"
    end
  end

  def gender_description
    genders.map(&:titleize).to_sentence
  end

  private

  def gender_present?
    errors.add(:base, "must include male or female or nonbinary entrants") unless male? || female? || nonbinary?
  end
end
