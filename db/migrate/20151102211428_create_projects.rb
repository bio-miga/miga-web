class CreateProjects < ActiveRecord::Migration[4.2]
  def change
    create_table :projects do |t|
      t.text :path
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :projects, [:user_id, :created_at]
  end
end
