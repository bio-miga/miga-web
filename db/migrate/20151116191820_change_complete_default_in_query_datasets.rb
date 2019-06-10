class ChangeCompleteDefaultInQueryDatasets < ActiveRecord::Migration[4.2]
  def change
     change_column_default :query_datasets, :complete, false
  end
end
