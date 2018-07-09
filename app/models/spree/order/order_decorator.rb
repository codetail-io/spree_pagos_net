Spree::Order.class_eval do
  has_one :pagos_net_bill,
          class_name: 'PagosNetBill', foreign_key: 'order_id'

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
      self.pagos_net_bill = PagosNetBill.create(data_pagosnet.merge(status: 'paid_out'))
    end
    payment = self.payments.last
    if payment.processing?
      payment.complete!
      self.next!
    end
  end

  def save_calculator_line_tushop
    self.line_items.each do |line_prod|
      calc_tushop_product = line_prod.try(:product).try(:calculator_line_tushop)
      next if calc_tushop_product.nil?
      params_line_tushop = calc_tushop_product.attributes
                                              .except('id',
                                                      'product_id',
                                                      'created_at',
                                                      'updated_at')
      params_line_tushop['line_item_id'] = line_prod.id
      Spree::CalculatorLineTushop.create(params_line_tushop)
    end
  end

  def create_items_pagosnet(payment_method_id)
    return if !self.pagos_net_bill.nil?
    pagos_net_bill = self.pagos_net_bill
    items_param = self.prepared_items_pagosnet(self.total.to_f)
    pagos_net = PagosNet.new(payment_method_id)
    resp = pagos_net.create_items_description(pagos_net_bill.transaction_id,
                                              items_param)
    # logger.info (resp[])
  end

  def prepared_items_pagosnet(total)
    items_result = []
    nro_item = 0
    items_total = 0
    self.line_items.each do |line_prod|
      items_total += (line_prod.price.to_f * line_prod.quantity)
      items_result << { numero_item: (nro_item = nro_item.next),
                        cantidad: line_prod.quantity,
                        descripcion: line_prod.try(:product).try(:name),
                        precio_unitario: line_prod.price.to_f }
    end
    items_result << { numero_item: (nro_item.next),
                      cantidad: 1,
                      descripcion: 'Costo por defecto del pedido',
                      precio_unitario: (total - items_total).round(2) }
  end
end