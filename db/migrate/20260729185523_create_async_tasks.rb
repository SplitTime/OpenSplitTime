class CreateAsyncTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :async_tasks do |t|
      t.references :parent, polymorphic: true, null: false, index: false
      t.references :user
      t.string :job_class, null: false
      t.string :context_key
      t.string :description
      t.integer :status, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :async_tasks, [:parent_type, :parent_id, :job_class, :context_key],
              name: "index_async_tasks_on_parent_and_job_class_and_context_key"
  end
end
