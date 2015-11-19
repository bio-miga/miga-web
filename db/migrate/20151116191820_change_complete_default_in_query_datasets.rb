class ChangeCompleteDefaultInQueryDatasets < ActiveRecord::Migration
  def change
     change_column_default :query_datasets, :complete, false
  end
end
