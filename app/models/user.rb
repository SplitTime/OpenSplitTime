class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  enum role: [:user, :admin]

  has_many :friendships
  has_many :participants, :through => :friendships
  has_many :ownerships
  has_many :races, :through => :ownerships

  after_initialize :set_default_role, :if => :new_record?

  def set_default_role
      self.role ||= :user
  end

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      if auth['info']
         user.name = auth['info']['name'] || ""
      end
    end
  end

end
