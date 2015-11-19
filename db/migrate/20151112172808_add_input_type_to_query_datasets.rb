class AddInputTypeToQueryDatasets < ActiveRecord::Migration
  def change
    add_column :query_datasets, :input_type, :string
  end
end
