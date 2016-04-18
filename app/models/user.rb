class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  enum role: [:user, :admin]
  enum pref_distance_unit: [:miles, :kilometers]
  enum pref_elevation_unit: [:feet, :meters]

  has_many :interests, dependent: :destroy
  has_many :participants, through: :interests
  has_many :ownerships, dependent: :destroy
  has_many :races, through: :ownerships
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
         user.last_name = auth['info']['name'] || ""    # TODO: figure out how to use oath with first_name/last_name model
      end
    end
  end

  def authorized_to_edit?(resource)
    self.admin? | ( self.id == resource.created_by )
  end

  def authorized_to_claim?(participant)
    return true if self.admin?
    return true if self.full_name == participant.full_name
    true # TODO future fuzzy match algorithm; also provide for admin contact and override
  end

  def full_name
    first_name + " " + last_name
  end
  
  def has_no_avatar?
    avatar.nil?
  end
  
  def has_avatar?
    !has_no_avatar?
  end

  def not_interested_in?(participant_id)
    interests.where(participant_id: participant_id).count < 1
  end

  def except_current_user(participants)
    participants.reject { |participant| participant.claimant == self }
  end

end
