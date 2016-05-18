class EffortRow
  include PersonalInfo
  attr_reader :parent_view_object, :id

  def initialize(parent_view_object, effort_id)
    @parent_view_object = parent_view_object
    @id = effort_id
  end

  def first_name
    parent_view_object.effort_data[id][:first_name]
  end

  def last_name
    parent_view_object.effort_data[id][:last_name]
  end

  def gender
    parent_view_object.effort_data[id][:gender]
  end

  def bib_number
    parent_view_object.effort_data[id][:bib_number]
  end

  def age
    parent_view_object.effort_data[id][:age]
  end

  def state_code
    parent_view_object.effort_data[id][:state_code]
  end

  def country_code
    parent_view_object.effort_data[id][:country_code]
  end

  def dropped_split_id
    parent_view_object.effort_data[id][:dropped_split_id]
  end

  def data_status
    parent_view_object.effort_data[id][:data_status]
  end

  def overall_place
    parent_view_object.overall_place(id)
  end
  
  def gender_place
    parent_view_object.gender_place(id)
  end

  def year
    parent_view_object.effort_data[id][:year]
  end

  def finish_status
    parent_view_object.finish_status(id)
  end

  def finish_time
    parent_view_object.finish_time(id)
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