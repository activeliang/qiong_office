class AddDealMethodToAbnormal < ActiveRecord::Migration[5.0]
  def change
    add_column :abnormals, :deal_method, :string
  end
end
