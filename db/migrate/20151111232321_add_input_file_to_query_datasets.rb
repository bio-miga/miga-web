class AddInputFileToQueryDatasets < ActiveRecord::Migration
  def change
    add_column :query_datasets, :input_file, :string
  end
end
