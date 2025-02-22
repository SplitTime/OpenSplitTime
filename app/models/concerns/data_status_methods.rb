module DataStatusMethods
  extend ActiveSupport::Concern

  included do
    scope :valid_status, -> { where(data_status: valid_statuses) }
    scope :invalid_status, -> { where(data_status: invalid_statuses) }
    validates :data_status, inclusion: {in: data_statuses.keys}, allow_nil: true
  end

  def data_status_numeric
    self.class.data_statuses[data_status]
  end

  def valid_status?
    self.class.valid_statuses.include?(data_status_numeric)
  end

  def invalid_status?
    self.class.invalid_statuses.include?(data_status_numeric)
  end

  module ClassMethods
    def valid_statuses
      self::VALID_STATUSES
    end

    def invalid_statuses
      data_statuses.values - self::VALID_STATUSES
    end

    def good!
      all.each { |resource| resource.good! }
    end
  end
end
