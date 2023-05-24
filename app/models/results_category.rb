# frozen_string_literal: true

class ResultsCategory < ApplicationRecord
  include Auditable

  INF = 1.0 / 0

  belongs_to :organization, optional: true
  has_many :results_template_categories, dependent: :destroy
  has_many :results_templates, through: :results_template_categories

  validates_presence_of :name, :identifier
  validates_uniqueness_of :name, scope: :organization
  validate :age_range_valid?
  validate :gender_present?

  attr_accessor :efforts

  attribute :invalid_efforts, :boolean

  # `position` and `fixed_position` are persisted on the results_template_categories
  # table, but can be set here for convenience, e.g., by ResultsTemplate#dup_with_categories
  attribute :position, :integer
  attribute :fixed_position, :boolean

  before_validation :set_identifier

  def self.invalid_category(attributes = {})
    standard_attributes = { name: "Invalid Efforts", male: true, female: true, invalid_efforts: true }
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
    elsif low_age == high_age
      "#{low_age}"
    else
      "#{low_age} to #{high_age}"
    end
  end

  def gender_description
    genders.map(&:titleize).to_sentence
  end

  private

  def age_range_valid?
    return if low_age.nil? || high_age.nil?

    errors.add(:base, "low age must be less than or equal to high age") unless low_age <= high_age
  end

  def gender_present?
    errors.add(:base, "must include male or female or nonbinary entrants") unless male? || female? || nonbinary?
  end

  def set_identifier
    organization_component = organization ? [organization.name.downcase.gsub(/\s/, "_")] : []
    gender_component = all_genders? ? ["combined"] : genders
    age_component = all_ages? ? ["overall"] : [age_description]
    self.identifier = [*organization_component, *gender_component, *age_component].join("_").downcase.gsub(/\s/, "_")
  end
end
