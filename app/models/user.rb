class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  enum role: [:user, :admin]
  enum pref_distance_unit: [:miles, :kilometers]
  enum pref_elevation_unit: [:feet, :meters]
  include Searchable

  has_many :interests, dependent: :destroy
  has_many :participants, through: :interests
  has_many :stewardships, dependent: :destroy
  has_many :races, through: :stewardships
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

  def authorized_to_edit?(resource)
    self.admin? | (self.id == resource.created_by)
  end

  def authorized_to_claim?(participant)
    return false if self.has_avatar?
    self.admin? | (self.last_name == participant.last_name) | (self.first_name == participant.first_name)
  end

  def authorized_for_live?(resource)
    self.admin? | (self.id == resource.created_by) | (resource.race && resource.race.stewards.include?(self))
  end

  def authorized_to_edit_personal?(effort)
    self.admin? | (effort.participant ? (self.avatar == effort.participant) : self.authorized_to_edit?(effort))
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

  def not_interested_in?(participant_id)
    interests.where(participant_id: participant_id).count < 1
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
      when 'date_asc'
        order(:confirmed_at)
      else
        order('users.confirmed_at DESC')
    end
  end

  def self.to_csv
    attributes = %w{id email full_name}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |user|
        csv << attributes.map{ |attr| user.send(attr) }
      end
    end
  end


end
