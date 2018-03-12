# frozen_string_literal: true

class SplitPresenter < BasePresenter

  delegate :id, :course, :base_name, :description, :distance_from_start, :vert_gain_from_start, :vert_loss_from_start,
           :latitude, :longitude, :elevation, :to_param, to: :split
  delegate :track_points, to: :course

  def initialize(split, params, current_user)
    @split = split
    @params = params
    @current_user = current_user
  end

  def course_splits
    @course_splits ||= split.course.ordered_splits
  end

  private

  attr_reader :split, :params, :current_user
end
