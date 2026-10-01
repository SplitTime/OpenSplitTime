class UserResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :first_name, index: true
  attribute :last_name, index: true
  attribute :role, index: true
  attribute :provider
  attribute :uid
  attribute :email, index: true
  attribute :encrypted_password
  attribute :reset_password_token
  attribute :reset_password_sent_at
  attribute :remember_created_at
  attribute :sign_in_count, form: false
  attribute :current_sign_in_at
  attribute :last_sign_in_at, index: true
  attribute :current_sign_in_ip
  attribute :last_sign_in_ip
  attribute :confirmation_token
  attribute :confirmed_at, index: true
  attribute :confirmation_sent_at
  attribute :unconfirmed_email
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :pref_distance_unit
  attribute :pref_elevation_unit
  attribute :slug
  attribute :phone
  attribute :http_endpoint
  attribute :https_endpoint
  attribute :phone_confirmation_token
  attribute :phone_confirmed_at
  attribute :phone_confirmation_sent_at
  attribute :exports_viewed_at
  attribute :exports, index: false

  # Associations
  attribute :slugs
  attribute :subscriptions
  attribute :watch_efforts
  attribute :stewardships
  attribute :organizations
  attribute :export_jobs
  attribute :import_jobs
  attribute :avatar

  def self.display_name(record)
    record.full_name
  end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
