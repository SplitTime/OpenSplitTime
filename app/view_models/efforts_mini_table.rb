# frozen_string_literal: true

class EffortsMiniTable

  def initialize(effort_ids_param)
    effort_ids = effort_ids_param.split(',')
    @efforts = Effort.where(id: effort_ids)
  end

  def effort_rows
    @effort_rows ||= efforts.map { |effort| EffortRow.new(effort) }
  end

  private

  attr_reader :efforts
end
