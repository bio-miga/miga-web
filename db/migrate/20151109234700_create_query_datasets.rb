class CreateQueryDatasets < ActiveRecord::Migration[4.2]
  def change
    create_table :query_datasets do |t|
      t.text :name
      t.boolean :complete
      t.references :user, index: true, foreign_key: true
      t.references :project, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :query_datasets, [:project_id, :created_at]
    add_index :query_datasets, [:user_id, :created_at]
    add_index :query_datasets, [:project_id, :user_id, :name], unique: true
  end
end
