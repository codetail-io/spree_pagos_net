class AddFieldTypeMethodOnPagosNetBill < ActiveRecord::Migration[5.2]
  def change
    add_column :pagos_net_bills, :type_method, :string
  end
end
