class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  enum role: [:user, :admin]

  has_many :interests, dependent: :destroy
  has_many :participants, :through => :interests
  has_many :ownerships, dependent: :destroy
  has_many :races, :through => :ownerships
  has_one :avatar, class_name: 'Participant'

  validates_presence_of :first_name, :last_name

  after_initialize :set_default_role, :if => :new_record?

  def set_default_role
      self.role ||= :user
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
    return true # TODO future fuzzy match algorithm; also provide for admin contact and override
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

end
