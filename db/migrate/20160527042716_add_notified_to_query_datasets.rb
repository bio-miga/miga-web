class AddNotifiedToQueryDatasets < ActiveRecord::Migration
  def up
    change_table :query_datasets do |t|
      t.boolean :notified, :default => false
    end
    QueryDataset.update_all ["notified = ?", true]
  end

  def down
    remove_column :query_datasets, :notified
  end

end
