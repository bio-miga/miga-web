class AddInputFileToQueryDatasets < ActiveRecord::Migration[4.2]
  def change
    add_column :query_datasets, :input_file, :string
  end
end
