# frozen_string_literal: true

class User < ApplicationRecord
  include PgSearch
  extend FriendlyId

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  enum role: [:user, :admin]
  enum pref_distance_unit: [:miles, :kilometers]
  enum pref_elevation_unit: [:feet, :meters]
  pg_search_scope :search_name_email, against: [:first_name, :last_name, :email], using: {tsearch: {any_word: true, prefix: true}}
  strip_attributes collapse_spaces: true
  friendly_id :slug_candidates, use: [:slugged, :history]
  phony_normalize :phone, country_code: 'US'

  has_many :subscriptions, dependent: :destroy
  has_many :interests, through: :subscriptions, source: :person
  has_many :stewardships, dependent: :destroy
  has_many :organizations, through: :stewardships
  has_one :avatar, class_name: 'Person'
  alias_attribute :sms, :phone
  alias_attribute :http, :http_endpoint
  alias_attribute :https, :https_endpoint

  validates_presence_of :first_name, :last_name
  validates_plausible_phone :phone, country_code: 'US', message: 'must be a valid US or Canada phone number'

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= :user
  end

  def self.current
    Thread.current[:current_user]
  end

  def self.current=(user)
    Thread.current[:current_user] = user
  end
  
  def self.search(search_param)
    search_param.present? ? search_name_email(search_param) : all
  end

  attr_accessor :has_json_web_token

  def to_s
    slug
  end

  def slug_candidates
    [:full_name, [:full_name, Date.today], [:full_name, Date.today, Time.current.strftime('%H:%M:%S')]]
  end

  def should_generate_new_friendly_id?
    slug.blank? || first_name_changed? || last_name_changed?
  end

  def authorized_fully?(resource)
    admin? || (id == resource.created_by) || resource.new_record? || owner_of?(resource)
  end

  def authorized_to_edit?(resource)
    authorized_fully?(resource) || steward_of?(resource)
  end

  def authorized_to_claim?(person)
    return false if self.has_avatar?
    admin? || (last_name == person.last_name) || (first_name == person.first_name)
  end

  def authorized_to_edit_personal?(effort)
    admin? || (effort.person ? (avatar == effort.person) : authorized_to_edit?(effort))
  end

  def owner_of?(resource)
    resource.respond_to?(:owner_id) ? resource.owner_id == self.id : false
  end

  def steward_of?(resource)
    resource.respond_to?(:stewards) ? resource.stewards.include?(self) : false
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def has_avatar?
    avatar.present?
  end
end
