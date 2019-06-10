class RemoveAccSeenFromQueryDatasets < ActiveRecord::Migration[4.2]
  def change
    remove_column :query_datasets, :acc_seen, :boolean
  end
end
