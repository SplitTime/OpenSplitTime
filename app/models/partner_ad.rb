class PartnerAd < ActiveRecord::Base
  belongs_to :event
  strip_attributes collapse_spaces: true
end
