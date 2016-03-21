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
  belongs_to :participant

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

end
