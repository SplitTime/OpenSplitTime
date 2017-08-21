class MakeEffortStartOffsetNotNullable < ActiveRecord::Migration
  def up
    efforts = Effort.where(start_offset: nil)
    efforts.each { |effort| effort.update_attributes(start_offset: 0) }
    change_column_null :efforts, :start_offset, false
  end

  def down
    change_column_null :efforts, :start_offset, true
  end
end
