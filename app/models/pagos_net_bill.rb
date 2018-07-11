class PagosNetBill < ApplicationRecord
  belongs_to :order, class_name: 'Spree::Order'

  def type_method_name
    return 'Efectivo' if self.type_method.to_s == 'payment_bank'
    return 'Tarjeta de Crédito' if self.type_method.to_s == 'credit_cart'
    return 'Portales Ebanking' if self.type_method.to_s == 'ebanking'
  end
end
