class ChangeDefaultBooleans < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:projects, :private, false)
    change_column_default(:projects, :official, true)
    change_column_default(:projects, :reference, false)
    change_column_default(:query_datasets, :complete, false)
    change_column_default(:query_datasets, :notified, false)
    change_column_default(:query_datasets, :complete_new, false)
    change_column_default(:users, :admin, false)
    change_column_default(:users, :activated, false)
    change_column_default(:users, :notify, true)
  end
end
