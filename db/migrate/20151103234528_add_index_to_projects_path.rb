class AddIndexToProjectsPath < ActiveRecord::Migration[4.2]
  def change
     add_index :projects, :path, unique: true
  end
end
