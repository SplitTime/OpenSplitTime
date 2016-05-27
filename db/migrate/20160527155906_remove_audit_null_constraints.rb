class RemoveAuditNullConstraints < ActiveRecord::Migration
  def change
    
    change_column_null :courses, :created_by, true
    change_column_null :courses, :updated_by, true

    change_column_null :efforts, :created_by, true
    change_column_null :efforts, :updated_by, true

    change_column_null :events, :created_by, true
    change_column_null :events, :updated_by, true

    change_column_null :locations, :created_by, true
    change_column_null :locations, :updated_by, true

    change_column_null :participants, :created_by, true
    change_column_null :participants, :updated_by, true

    change_column_null :races, :created_by, true
    change_column_null :races, :updated_by, true

    change_column_null :split_times, :created_by, true
    change_column_null :split_times, :updated_by, true

    change_column_null :splits, :created_by, true
    change_column_null :splits, :updated_by, true

  end
end
