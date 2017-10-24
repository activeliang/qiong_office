class AddImportIdToAbnormal < ActiveRecord::Migration[5.0]
  def change
    add_column :abnormals, :import_id, :integer
  end
end
