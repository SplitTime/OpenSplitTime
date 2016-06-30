class EffortsMiniTable

  attr_reader :effort_rows

  def initialize(effort_ids_param)
    effort_ids = effort_ids_param.split(',').flatten
    @efforts = Effort.where(id: effort_ids)
    @effort_rows = []
    create_effort_rows
  end

  private

  attr_reader :efforts

  def create_effort_rows
    efforts.each do |effort|
      effort_row = EffortRow.new(effort)
      effort_rows << effort_row
    end
  end

end