class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  enum role: [:user, :admin]
  enum pref_distance_unit: [:miles, :kilometers]
  enum pref_elevation_unit: [:feet, :meters]
  include PgSearch
  pg_search_scope :search_name_email, against: [:first_name, :last_name, :email], using: {tsearch: {any_word: true, prefix: true}}
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  phony_normalize :phone, default_country_code: 'US'
  strip_attributes collapse_spaces: true

  has_many :subscriptions, dependent: :destroy
  has_many :interests, through: :subscriptions, source: :participant
  has_many :stewardships, dependent: :destroy
  has_many :organizations, through: :stewardships
  has_one :avatar, class_name: 'Participant'
  alias_attribute :sms, :phone
  alias_attribute :http, :http_endpoint
  alias_attribute :https, :https_endpoint

  validates_presence_of :first_name, :last_name
  validates :phone, phony_plausible: true

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

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      if auth['info']
        user.last_name = auth['info']['name'] || "" # TODO: figure out how to use oath with first_name/last_name model
      end
    end
  end

  def self.search(search_param)
    search_param.present? ? search_name_email(search_param) : all
  end

  def self.sort(sort_param)
    case sort_param
    when 'first'
      order(:first_name)
    when 'last'
      order(:last_name)
    when 'email'
      order(:email)
    when 'avatar_desc'
      includes(:avatar).order('participants.last_name DESC')
    when 'avatar_asc'
      includes(:avatar).order('participants.last_name')
    when 'date_asc'
      order(:confirmed_at)
    else
      order('users.confirmed_at DESC')
    end
  end

  attr_accessor :has_json_web_token

  def to_s
    slug
  end

  def slug_candidates
    [:full_name, [:full_name, Date.today], [:full_name, Date.today, Time.current.strftime('%H:%M:%S')]]
  end

  def authorized_to_edit?(resource)
    admin? || (id == resource.created_by) || resource.new_record?
  end

  def authorized_to_claim?(participant)
    return false if self.has_avatar?
    admin? || (last_name == participant.last_name) || (first_name == participant.first_name)
  end

  def authorized_for_live?(resource)
    admin? || (id == resource.created_by) || steward_of?(resource) || resource.new_record?
  end

  def authorized_to_edit_personal?(effort)
    admin? || (effort.participant ? (avatar == effort.participant) : authorized_to_edit?(effort))
  end

  def steward_of?(resource)
    resource.organization && resource.organization.stewards.include?(self)
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def has_no_avatar?
    avatar.nil?
  end

  def has_avatar?
    avatar.present?
  end

  def interested_in?(participant)
    interests.include?(participant)
  end

  def add_interest(participant)
    interests << participant
  end

  def remove_interest(participant)
    interests.delete(participant)
  end

  def except_current_user(participants)
    participants.reject { |participant| participant.claimant == self }
  end
end
