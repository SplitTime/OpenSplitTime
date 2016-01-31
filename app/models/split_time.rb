class SplitTime < ActiveRecord::Base
  enum data_status: [:wrong, :questionable, :good]

  belongs_to :effort
  belongs_to :split
end
