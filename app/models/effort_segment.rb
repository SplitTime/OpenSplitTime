# frozen_string_literal: true

class EffortSegment < ApplicationRecord
  readonly

  def self.delete_for_effort(effort)
    query = EffortSegmentQuery.delete_for_effort(effort)
    ActiveRecord::Base.connection.execute(query)
  end

  def self.delete_for_split_time(split_time)
    query = EffortSegmentQuery.delete_for_split_time(split_time)
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
