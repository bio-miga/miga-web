class AddInputFile2ToQueryDatasets < ActiveRecord::Migration
  def change
    add_column :query_datasets, :input_file_2, :string
  end
end
