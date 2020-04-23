class AddPrivateToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :private, :boolean, default: false
  end
end
