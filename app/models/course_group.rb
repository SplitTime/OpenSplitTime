# frozen_string_literal: true

class CourseGroup < ApplicationRecord
  include DelegatedConcealable
  include Delegable
  extend FriendlyId

  friendly_id :name, use: [:slugged, :history]
  has_paper_trail

  belongs_to :organization
  has_many :course_group_courses, dependent: :destroy
  has_many :courses, through: :course_group_courses
  has_many :events, through: :courses

  validates_presence_of :name, :organization

  scope :with_policy_scope_attributes, -> { from(select("course_groups.*, false as concealed"), :course_groups) }
end
