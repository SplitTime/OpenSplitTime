# frozen_string_literal: true

class Analytics::FileDownload < ApplicationRecord
  belongs_to :user
  belongs_to :record, polymorphic: true
end
