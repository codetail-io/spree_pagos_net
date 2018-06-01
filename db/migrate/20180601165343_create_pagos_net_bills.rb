class CreatePagosNetBills <  ActiveRecord::Migration[4.2]
  def change
    create_table :pagos_net_bills do |t|
      t.integer :order_id, :order, foreign_key: true
      t.integer :user_id,:user, foreign_key: true
      t.integer :status
      t.string :transaction_id
      t.datetime :due_date
      t.decimal :amount_price, precision: 10, scale: 2
      t.string :payed_date
      t.string :origen_transaccion
      t.string :pais
      t.string :departamento
      t.string :ciudad
      t.string :entidad
      t.string :agencia
      t.string :operador
      t.string :codigo_autorizacion
      t.string :codigo_control
      t.string :code_recaudacion
      t.float :monto_credito_fiscal
      t.string :lote_dosificacion
      t.string :nro_renta_recibo
      t.string :nit_facturar
      t.string :nombre_facturar
      t.timestamps
    end
  end
end
