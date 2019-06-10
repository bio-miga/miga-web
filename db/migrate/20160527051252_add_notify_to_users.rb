class AddNotifyToUsers < ActiveRecord::Migration[4.2]
  def up
    change_table :users do |t|
      t.boolean :notify, :default => true
    end
    User.update_all ["notify = ?", true]
  end

  def down
    remove_column :users, :notify
  end

end
