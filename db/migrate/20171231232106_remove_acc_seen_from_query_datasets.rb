class RemoveAccSeenFromQueryDatasets < ActiveRecord::Migration
  def change
    remove_column :query_datasets, :acc_seen, :boolean
  end
end
