class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.column :external_id, :string
      t.column :name, :string
      t.timestamps
    end
  end
end
