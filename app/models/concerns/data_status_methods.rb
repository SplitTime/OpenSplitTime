module DataStatusMethods
  extend ActiveSupport::Concern

  included do
    scope :valid_status, -> { where(data_status: VALID_STATUSES) }
    validates :data_status, inclusion: {in: self.data_statuses.keys}, allow_nil: true
  end

  def data_status_numeric
    self.class.data_statuses[data_status]
  end

  def valid_status?
    self.class::VALID_STATUSES.include?(data_status_numeric)
  end

  module ClassMethods

    def good!
      all.each { |resource| resource.good! }
    end
  end
end