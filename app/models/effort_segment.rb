# frozen_string_literal: true

class EffortSegment < ApplicationRecord
  readonly

  def self.destroy_for_effort(effort)
    query = EffortSegmentQuery.destroy_for_effort(effort)
    ActiveRecord::Base.connection.execute(query)
  end

  def self.destroy_for_split_time(split_time)
    query = EffortSegmentQuery.destroy_for_split_time(split_time)
    ActiveRecord::Base.connection.execute(query)
  end

  def self.set_for_effort(effort)
    query = EffortSegmentQuery.set_for_effort(effort)
    ActiveRecord::Base.connection.execute(query)
  end

  def self.set_for_split_time(split_time)
    query = EffortSegmentQuery.set_for_split_time(split_time)
    ActiveRecord::Base.connection.execute(query)
  end
end
