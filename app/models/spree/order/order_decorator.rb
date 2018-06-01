Spree::Order.class_eval do
  def self.find_payment_recaudacion(code_recaudacion)
    find_by(number: code_recaudacion)
  end

  def can_complete?
    self.try(:payments).try(:last).try(:state) == 'processing'
  end

  def complete_pagosnet(data_pagosnet)
    self.next
  end
end