class AddIndexToProjectsPath < ActiveRecord::Migration
  def change
     add_index :projects, :path, unique: true
  end
end
