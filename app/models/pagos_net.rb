class PagosNet
  attr_accessor :shopping_cart

  # PAGOS NET IFRAME TARJETA DE CREDITO
  URL_PAGOSNET_CREDITCARD = 'https://test.sintesis.com.bo/payment/#/pay'
  NRO_CLIENT = 68
  ENTIDAD = 115
  KEY_AUTHENTICATE = 'JEn1jJsD5hFrip4jzHODyA=='


  NEW_TRANSACTION = 'A'
  CHANGE_TRANSACTION = 'M'
  DESTROY_TRANSACTION = 'B'
  TYPE_CURRENCY = 'BS'
  PRECEDENCIA_COBRO = 'T'
  DESCRIPTION_RECAUDACION = 'Pedido de Importacion de un producto Amazon [Tushop]'

  # __________ codigo recaudacion
  OPTS_DEFAULT = { 'type_transaction' => 'A',
                   'currency' => 'BS',
                   'description_recaudacion' => 'Pagar via pagos net',
                   'precedencia_cobro' => 'T',
                   'description_planilla' => 'planilla 1' }

  def create_transaction(code_transaction, amount_money, user_data, type_pay, opts = {})
    params = prepare_payment_params(code_transaction, amount_money, user_data, type_pay, opts)
    client = Savon.client(wsdl: ENV['URL_PAGOSNET'])
    resp_registro_plan = client.call(:registro_plan, message: params)
  end

  def prepare_payment_params(code_transaction, amount_money, user_data, type_pay, opts)
    opts_final = OPTS_DEFAULT.merge(opts)
    {
      datos:
      {
        transaccion: opts_final['type_transaction'],
        nombre_comprador: user_data['fiscal_name'],
        documento_identidad_comprador: user_data['ci'],
        codigo_comprador: user_data['id'],
        fecha: Time.zone.now.strftime('%Y%m%d'),
        hora: Time.zone.now.strftime('%H%M%S'),
        correo_electronico: user_data['email'],
        moneda: opts_final['currency'],
        codigo_recaudacion: code_transaction,
        descripcion_recaudacion: opts_final['description_recaudacion'],
        fecha_vencimiento: 0,
        hora_vencimiento: 0,
        categoria_producto: type_pay,
        precedencia_cobro: opts_final['precedencia_cobro'],
        planillas:
        {
          numero_pago: 1,
          monto_pago: amount_money.to_f,
          descripcion: 'Pedido de TuShop',
          monto_credito_fiscal: amount_money.to_f,
          nombre_factura: user_data['fiscal_name'],
          nit_factura: user_data['ci']
        }
      },
      cuenta: ENV['USER_NAME'],
      password: ENV['PASSWORD']
    }
  end
  # __________ end

  def send_request_pagosnet(id_before_recaudacion = nil)
    amount = total_price_boliviano
    codigo_recaudacion = "#{id_before_recaudacion}#{shopping_cart_id}"
    codigo_producto = code_product
    credito_fiscal = amount

    fecha = I18n.l Time.zone.today, format: :pagos_net_day
    time = I18n.l Time.zone.now, format: :pagos_net_hour

    client = Savon.client(wsdl: URL_PAGOSNET)
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
    client = Savon.client(wsdl: URL_PAGOSNET)

    items_registro_pagosnet = @shopping_cart.pagos_net_items(amount)

    response = client.call(:registro_item,
                           message: {
                               datos: { transaccion: NEW_TRANSACTION,
                                       id_transaccion: transaction_id,
                                       numero_pago: 1,
                                       items: items_registro_pagosnet },
                               cuenta: USER_NAME,
                               password: PASSWORD
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

    client = Savon.client(wsdl: URL_PAGOSNET)
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
                               cuenta: USER_NAME,
                               password: PASSWORD
                           })
    return [response, amount, codigo_recaudacion]
    # return [(response.body[:registro_plan_response][:return][:codigo_error] == '0'),
    #         (response.body[:registro_plan_response][:return][:descripcion_error].to_s)]
  end

  def request_pagosnet_tarjeta
    client = Savon.client(wsdl: URL_PAGOSNET)
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
                               cuenta: USER_NAME,
                               password: PASSWORD
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

    client = Savon.client(wsdl: URL_PAGOSNET)
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
                               cuenta: USER_NAME,
                               password: PASSWORD
                           })

    return response
  end
end
