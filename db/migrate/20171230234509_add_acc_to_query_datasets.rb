class AddAccToQueryDatasets < ActiveRecord::Migration
  def change
    add_column :query_datasets, :acc, :string
    add_column :query_datasets, :acc_seen, :boolean, default: false
    add_index :query_datasets, :acc, unique: true
  end
end
