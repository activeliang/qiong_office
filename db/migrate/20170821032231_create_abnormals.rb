class CreateAbnormals < ActiveRecord::Migration[5.0]
  def change
    create_table :abnormals do |t|

      t.timestamps
    end
  end
end
