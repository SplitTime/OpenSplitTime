module Concealable
  extend ActiveSupport::Concern

  include SetOperations

  included do
    scope :concealed, -> { where(concealed: true) }
    scope :visible, -> { where(concealed: false) }
  end

end