class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  enum role: [:user, :admin]
  enum pref_distance_unit: [:miles, :kilometers]
  enum pref_elevation_unit: [:feet, :meters]
  include Searchable
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  has_many :connections, dependent: :destroy
  has_many :interests, through: :connections, source: :participant
  has_many :stewardships, dependent: :destroy
  has_many :organizations, through: :stewardships
  has_one :avatar, class_name: 'Participant'

  validates_presence_of :first_name, :last_name

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

  def self.search(search_param)
    return all if search_param.blank?
    name_email_search(search_param)
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
        includes(:participants).order('participants.last_name DESC')
      when 'avatar_asc'
        includes(:participants).order('participants.last_name')
      when 'date_asc'
        order(:confirmed_at)
      else
        order('users.confirmed_at DESC')
    end
  end
end