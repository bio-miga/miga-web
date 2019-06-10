class AddInputTypeToQueryDatasets < ActiveRecord::Migration[4.2]
  def change
    add_column :query_datasets, :input_type, :string
  end
end
