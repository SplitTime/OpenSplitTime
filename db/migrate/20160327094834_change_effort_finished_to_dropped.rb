class ChangeEffortFinishedToDropped < ActiveRecord::Migration
  def change
    rename_column :efforts, :finished, :dropped
  end
end
