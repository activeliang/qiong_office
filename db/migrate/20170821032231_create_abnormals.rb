class CreateAbnormals < ActiveRecord::Migration[5.0]
  def change
    create_table :abnormals do |t|
      t.string :envelop, :principal, :raw_delivery, :new_delivery, :faulter, :image, :department, :client, :model_no, :merchandiser
      t.text :reason, :remarks
      t.integer :quantity, default: 1
      t.datetime :input_time
      t.timestamps
    end
  end
end
