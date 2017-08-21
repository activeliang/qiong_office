class CreateAbnormals < ActiveRecord::Migration[5.0]
  def change
    create_table :abnormals do |t|
      t.string :envelop, :principal, :input_time, :raw_delivery, :new_delivery, :faulter, :image, :department, :client, :model_no, :merchandiser
      t.text :reason, :remarks
      t.integer :quantity, default: 1
      t.timestamps
    end
  end
end
