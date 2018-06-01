Spree::Order.class_eval do
  has_one :pagos_net_bill
  def self.find_payment_recaudacion(code_recaudacion)
    find_by(number: code_recaudacion)
  end

  def can_complete?
    self.try(:payments).try(:last).try(:state) == 'processing'
  end

  def complete_pagosnet(data_pagosnet)
    if self.pagos_net_bill
      self.pagos_net_bill.update(data_pagosnet.merge(status: 'paid_out'))
    else
      self.pagos_net_bill.create(data_pagosnet.merge(status: 'paid_out'))
    end
    self.payment.last.next
  end
end