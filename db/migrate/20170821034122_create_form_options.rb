class CreateFormOptions < ActiveRecord::Migration[5.0]
  def change
    create_table :form_options do |t|
      t.string :field
      t.text :content
      t.timestamps
    end
  end
end
