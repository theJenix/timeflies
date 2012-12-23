class CreateWorkLogs < ActiveRecord::Migration
  def change
    create_table :work_logs do |t|
      t.column :hours, :integer
      t.column :description, :string
      t.integer :task_id
      t.timestamps
    end
  end
end
