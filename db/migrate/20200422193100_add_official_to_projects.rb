class AddOfficialToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :official, :boolean, default: true
    add_index :projects, :private
    add_index :projects, :official
  end
end
