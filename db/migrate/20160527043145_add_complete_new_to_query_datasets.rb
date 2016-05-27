class AddCompleteNewToQueryDatasets < ActiveRecord::Migration
  def up
    change_table :query_datasets do |t|
      t.boolean :complete_new, :default => false
    end
    QueryDataset.update_all ["complete_new = ?", false]
  end

  def down
    remove_column :query_datasets, :complete_new
  end

end
