class AddNotifyToUsers < ActiveRecord::Migration
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
