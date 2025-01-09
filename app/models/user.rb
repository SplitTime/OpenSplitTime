class User < ApplicationRecord
  include PgSearch::Model
  include ::CapitalizeAttributes
  extend FriendlyId

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, omniauth_providers: [:facebook, :google_oauth2]

  enum role: [:user, :admin]
  enum pref_distance_unit: [:miles, :kilometers]
  enum pref_elevation_unit: [:feet, :meters]

  strip_attributes collapse_spaces: true
  capitalize_attributes :first_name, :last_name
  friendly_id :slug_candidates, use: [:slugged, :history]

  has_many :subscriptions, dependent: :destroy
  has_many :interests, through: :subscriptions, source: :subscribable, source_type: "Person"
  has_many :watch_efforts, through: :subscriptions, source: :subscribable, source_type: "Effort"
  has_many :stewardships, dependent: :destroy
  has_many :organizations, through: :stewardships
  has_many :export_jobs, dependent: :destroy
  has_many :import_jobs, dependent: :destroy
  has_many :credentials, dependent: :destroy
  has_many_attached :exports
  has_one :avatar, class_name: "Person", dependent: :nullify
  alias_attribute :sms, :phone
  alias_attribute :http, :http_endpoint
  alias_attribute :https, :https_endpoint

  scope :with_avatar_names, lambda {
    from(select("users.*, people.first_name as avatar_first_name, people.last_name as avatar_last_name")
                  .left_joins(:avatar), :users)
  }

  validates_presence_of :first_name, :last_name
  validates :phone, format: {with: /\+1\d{9}/, message: "must be a valid US or Canada phone number"}, if: :phone?

  before_validation :normalize_phone, if: :phone?
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

  def self.from_omniauth(auth)
    existing_user = find_by(email: auth.info.email)

    if existing_user
      existing_user.update(provider: auth.provider, uid: auth.uid)
      existing_user.skip_confirmation!
      return existing_user
    end

    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.email = auth.info.email
      user.password = ::Devise.friendly_token[0, 20]
      user.skip_confirmation!
    end
  end

  def self.search(search_param)
    search_param.present? ? search_name_email(search_param) : all
  end

  def self.search_name_email(search_param)
    where("users.first_name ilike ? or users.last_name ilike ? or users.email ilike ?",
          "#{search_param}%", "#{search_param}%", "%#{search_param}%")
  end

  # @return [String]
  def to_s
    slug
  end

  # @return [[Symbol, [Symbol, Date], [Symbol, Date, String]]]
  def slug_candidates
    [:full_name, [:full_name, Date.today], [:full_name, Date.today, Time.current.strftime("%H:%M:%S")]]
  end

  # @return [Boolean]
  def should_generate_new_friendly_id?
    slug.blank? || first_name_changed? || last_name_changed?
  end

  # @return [Boolean]
  def associated_with_entrant?(lottery_entrant)
    ::LotteryEntrant.belonging_to_user(self).include?(lottery_entrant)
  end

  # @return [Boolean]
  def authorized_for_lotteries?(resource)
    admin? || owner_of?(resource) || lottery_steward_of?(resource)
  end

  # @return [Boolean]
  def authorized_fully?(resource)
    admin? || resource.new_record? || owner_of?(resource)
  end

  # @return [Boolean]
  def authorized_to_edit?(resource)
    authorized_fully?(resource) || steward_of?(resource)
  end

  # @return [Boolean]
  def authorized_to_claim?(person)
    return false if has_avatar?

    admin? || (last_name == person.last_name) || (first_name == person.first_name)
  end

  # @return [Boolean]
  def authorized_to_edit_personal?(effort)
    admin? || (effort.person ? (avatar == effort.person) : authorized_to_edit?(effort))
  end

  # @return [Boolean]
  def authorized_to_manage_service?(organization, lottery_entrant)
    admin? || owner_of?(organization) || steward_of?(organization) || associated_with_entrant?(lottery_entrant)
  end

  # @return [Boolean]
  def lottery_steward_of?(resource)
    return false unless resource.respond_to?(:stewards)

    resource.stewards.where(stewardships: {level: :lottery_manager}).include?(self)
  end

  # @return [Boolean]
  def owner_of?(resource)
    resource.respond_to?(:owner_id) ? resource.owner_id == id : false
  end

  # @return [Boolean]
  def steward_of?(resource)
    resource.respond_to?(:stewards) ? resource.stewards.include?(self) : false
  end

  # @return [Array<Integer>]
  def delegated_organization_ids
    Organization.authorized_for(self).pluck(:id)
  end

  # @return [Array<Integer>]
  def owned_organization_ids
    Organization.owned_by(self).pluck(:id)
  end

  # @return [String]
  def full_name
    [first_name, last_name].join(" ")
  end

  # @return [Boolean]
  def has_avatar?
    avatar.present?
  end

  # @return [Boolean]
  def has_credentials_for?(service_identifier)
    credentials.for_service(service_identifier).exists?
  end

  # @return [Boolean]
  def all_credentials_for?(service_identifier)
    service = Connectors::Service::BY_IDENTIFIER[service_identifier]
    return false if service.blank?

    credentials.for_service(service_identifier).pluck(:key).sort == service.credential_keys.sort
  end

  # @return [Boolean]
  def from_omniauth?
    provider? && uid?
  end

  private

  def normalize_phone
    phone.gsub!(/[^+\d]/, "")
    phone.gsub!(/\A\+?1?/, "")
    self.phone = "+1" + phone if phone.length == 10
    self.phone = phone.presence
  end
end
