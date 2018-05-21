class PagosNet
  attr_accessor :shopping_cart

  NEW_TRANSACTION = 'A'
  CHANGE_TRANSACTION = 'M'
  DESTROY_TRANSACTION = 'B'
  TYPE_CURRENCY = 'BS'
  PRECEDENCIA_COBRO = 'T'
  DESCRIPTION_RECAUDACION = 'Pedido de Importacion de un producto Amazon [Tushop]'

  def initialize(shopping_cart)
    @shopping_cart = shopping_cart
  end

  def shopping_cart_id
    return @shopping_cart.id
  end

  def user_fiscal_full_name
    return (@shopping_cart.try(:fiscal_data).try(:full_name) || 'No data.')
  end

  def user_name
    return (@shopping_cart.user_name || 'No data.')
  end

  def user_last_name
    return @shopping_cart.user_last_name
  end

  def user_ci
    return (@shopping_cart.try(:fiscal_data).try(:ci_nit) || 'No data.')
  end

  def user_id
    return (@shopping_cart.try(:user_id) || 'No data.')
  end

  def user_email
    # return (@shopping_cart.try(:user_email) || 'No data.')
    "clientes#{@shopping_cart.id}@tushopbolivia.com"
  end

  def user_nro_telf
    return @shopping_cart.user_nro_telf
  end

  def user_address
    return @shopping_cart.user_address
  end

  def cart_id_transaccion
    return (@shopping_cart.try(:pagosnet_bill).try(:transaction_id) || 'No data.')
  end

  def total_price
    return @shopping_cart.total_price
  end

  def total_price_boliviano
    return @shopping_cart.converter_boliviano +
           @shopping_cart.shipment_price.to_f -
           (@shopping_cart.coupon.price_off rescue 0)
    # rescue
    #   nil
  end

  def recaudacion_codigo
    result = (@shopping_cart.recaudacion_codigo)

    return result
  end

  def code_product
    result = '1'
    if pagosnet_creditcard?
      result = '2'
    end

    return result
  end

  def pagosnet_creditcard?
    @shopping_cart.try(:payment_method).try(:to_sym) == :pagos_net_creditcard
    # rescue
    #   return false
  end

  def send_request_pagosnet(id_before_recaudacion = nil)
    amount = total_price_boliviano
    codigo_recaudacion = "#{id_before_recaudacion}#{shopping_cart_id}"
    codigo_producto = code_product
    credito_fiscal = amount

    fecha = I18n.l Time.zone.today, format: :pagos_net_day
    time = I18n.l Time.zone.now, format: :pagos_net_hour

    client = Savon.client(wsdl: ENV['URL_PAGOSNET'])
    response = client.call(:registro_plan,
                           message: {
                               datos: {
                                   transaccion: NEW_TRANSACTION,
                                   nombre_comprador: user_fiscal_full_name,
                                   documento_identidad_comprador: user_ci,
                                   codigo_comprador: user_id,
                                   fecha: fecha,
                                   hora: time,
                                   correo_electronico: user_email,
                                   moneda: TYPE_CURRENCY,
                                   codigo_recaudacion: codigo_recaudacion,
                                   descripcion_recaudacion: DESCRIPTION_RECAUDACION,
                                   fecha_vencimiento: 0,
                                   hora_vencimiento: 0,
                                   categoria_producto: codigo_producto,
                                   precedencia_cobro: PRECEDENCIA_COBRO,
                                   planillas: {
                                       numero_pago: 1,
                                       monto_pago: amount,
                                       descripcion: 'Pedido de TuShop',
                                       monto_credito_fiscal: credito_fiscal,
                                       nombre_factura: user_fiscal_full_name,
                                       nit_factura: user_ci
                                   }
                               },
                               cuenta: ENV['USER_NAME'],
                               password: ENV['PASSWORD']
                           })

    return [response, amount, codigo_recaudacion]
  end

  def sent_request_items_pagosnet(transaction_id, amount)
    client = Savon.client(wsdl: ENV['URL_PAGOSNET'])

    items_registro_pagosnet = @shopping_cart.pagos_net_items(amount)

    response = client.call(:registro_item,
                           message: {
                               datos: { transaccion: NEW_TRANSACTION,
                                       id_transaccion: transaction_id,
                                       numero_pago: 1,
                                       items: items_registro_pagosnet },
                               cuenta: ENV['USER_NAME'],
                               password: ENV['PASSWORD']
                           })
    puts '>>>>>>>>>> REGISTRAR ITEM PAGOS NET'
    puts response.body
    puts '<<<<<<<<<< END PAGOS NET'
  rescue => e
    puts '>>>>>>>>>> REGISTRAR ITEM PAGOS NET'
    puts e.message
    puts '<<<<<<<<<< END PAGOS NET'
  end

  def modify_request_pagosnet(options = {})
    amount = total_price_boliviano
    codigo_recaudacion = recaudacion_codigo
    credito_fiscal = amount
    opt = { user_name: user_fiscal_full_name,
            user_ci: user_ci,
            user_id: user_id,
            user_email: user_email,
            code_product: code_product }
    opt = opt.merge(options)

    fecha = I18n.l Time.zone.today, format: :pagos_net_day
    time = I18n.l Time.zone.now, format: :pagos_net_hour

    client = Savon.client(wsdl: ENV['URL_PAGOSNET'])
    response = client.call(:registro_plan,
                           message: {
                               datos: {
                                   transaccion: CHANGE_TRANSACTION,
                                   nombre_comprador: opt[:user_name],
                                   documento_identidad_comprador: opt[:user_ci],
                                   codigo_comprador: opt[:user_id],
                                   fecha: fecha,
                                   hora: time,
                                   correo_electronico: opt[:user_email],
                                   moneda: TYPE_CURRENCY,
                                   codigo_recaudacion: codigo_recaudacion,
                                   descripcion_recaudacion: DESCRIPTION_RECAUDACION,
                                   fecha_vencimiento: 0,
                                   hora_vencimiento: 0,
                                   categoria_producto: opt[:code_product],
                                   precedencia_cobro: PRECEDENCIA_COBRO,
                                   planillas: {
                                       numero_pago: 1,
                                       monto_pago: amount,
                                       descripcion: 'Pedido de TuShop',
                                       monto_credito_fiscal: credito_fiscal,
                                       nombre_factura: opt[:user_name],
                                       nit_factura: opt[:user_ci]
                                   }
                               },
                               cuenta: ENV['USER_NAME'],
                               password: ENV['PASSWORD']
                           })
    return [response, amount, codigo_recaudacion]
    # return [(response.body[:registro_plan_response][:return][:codigo_error] == '0'),
    #         (response.body[:registro_plan_response][:return][:descripcion_error].to_s)]
  end

  def request_pagosnet_tarjeta
    client = Savon.client(wsdl: ENV['URL_PAGOSNET'])
    response = client.call(:registro_tarjeta_habiente,
                           message: {
                               datos: {
                                   apellido: user_last_name,
                                   ciudad: 'La Paz',
                                   correo_electronico: user_email,
                                   departamento: 'La Paz',
                                   direccion: 'No data.',
                                   id_transaccion: cart_id_transaccion,
                                   nombre: user_name,
                                   pais: 'Bolivia',
                                   telefono: user_nro_telf,
                                   transaccion: NEW_TRANSACTION
                               },
                               cuenta: ENV['USER_NAME'],
                               password: ENV['PASSWORD']
                           })
    puts '>>>>>>> PAGOSNET TARJETA'
    puts response
    puts '<<<<<<< END TARJETA'
    return response
  end

  def destroy_request_pagosnet
    amount = total_price_boliviano
    codigo_recaudacion = recaudacion_codigo
    codigo_producto = code_product
    credito_fiscal = amount

    # t = Time.now
    fecha = I18n.l Time.zone.today, format: :pagos_net_day
    time = I18n.l Time.zone.now, format: :pagos_net_hour

    client = Savon.client(wsdl: ENV['URL_PAGOSNET'])
    response = client.call(:registro_plan,
                           message: {
                               datos: {
                                   transaccion: DESTROY_TRANSACTION,
                                   nombre_comprador: user_name,
                                   documento_identidad_comprador: user_ci,
                                   codigo_comprador: user_id,
                                   fecha: fecha,
                                   hora: time,
                                   correo_electronico: user_email,
                                   moneda: TYPE_CURRENCY,
                                   codigo_recaudacion: codigo_recaudacion,
                                   descripcion_recaudacion: DESCRIPTION_RECAUDACION,
                                   fecha_vencimiento: 0,
                                   hora_vencimiento: 0,
                                   categoria_producto: codigo_producto,
                                   precedencia_cobro: PRECEDENCIA_COBRO,
                                   planillas: {
                                       numero_pago: 1,
                                       monto_pago: amount,
                                       descripcion: 'Pedido de TuShop',
                                       monto_credito_fiscal: credito_fiscal,
                                       nombre_factura: user_name,
                                       nit_factura: user_ci
                                   }
                               },
                               cuenta: ENV['USER_NAME'],
                               password: ENV['PASSWORD']
                           })

    return response
  end
end
