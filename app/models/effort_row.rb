class EffortRow
  include PersonalInfo
  attr_reader :display_group, :id

  def initialize(display_group, effort_id)
    @display_group = display_group
    @id = effort_id
  end

  def first_name
    display_group.effort_data[id][:first_name]
  end

  def last_name
    display_group.effort_data[id][:last_name]
  end

  def gender
    display_group.effort_data[id][:gender]
  end

  def bib_number
    display_group.effort_data[id][:bib_number]
  end

  def age
    display_group.effort_data[id][:age]
  end

  def state_code
    display_group.effort_data[id][:state_code]
  end

  def country_code
    display_group.effort_data[id][:country_code]
  end

  def dropped_split_id
    display_group.effort_data[id][:dropped_split_id]
  end

  def data_status
    display_group.effort_data[id][:data_status]
  end

  def place
    display_group.place(id)
  end

  def year
    display_group.effort_data[id][:year]
  end

  def finish_status
    display_group.finish_status(id)
  end

  def finish_time
    display_group.finish_time(id)
  end

  def bad?
    data_status == Effort.data_statuses[:bad]
  end

  def questionable?
    data_status == Effort.data_statuses[:questionable]
  end

  def good?
    data_status == Effort.data_statuses[:good]
  end

  def confirmed?
    data_status == Effort.data_statuses[:confirmed]
  end

end