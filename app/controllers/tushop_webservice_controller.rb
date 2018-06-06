class TushopWebserviceController < ApplicationController
  # include WashOut::SOAP
  soap_service namespace: 'urn:wsComelecServer'
  # soap_service namespace: 'http://localhost:3000/tushop_webservice/action'

  USER_WEB_SERVICE = 'tushop_webservice'
  PASSWORD_WEB_SERVICE = 'tushop_password'
  RESPONSE_MESSAGE = ['Registro exitoso',
                      'Error al registrar el pago',
                      'Recaudación duplicada',
                      'Reversión duplicada',
                      'No fue posible revertir, txt original no existe',
                      'Usuario o password son erroneos',
                      'Error en el envio de datos']
  TRANSACCION_PAGAR = 'P'
  TRANSACCION_REVERTIR = 'R'
  class WsTransaccion < WashOut::Type
    type_name('WsTransaccion')
    map(CodigoEmpresa: :integer,
        CodigoRecaudacion: :string,
        CodigoProducto: :string,
        NumeroPago: :integer,
        Fecha: :integer,
        Secuencial: :integer,
        Hora: :integer,
        OrigenTransaccion: :string,
        Pais: :integer,
        Departamento: :integer,
        Ciudad: :integer,
        Entidad: :string,
        Agencia: :string,
        Operador: :integer,
        Monto: :double,
        LoteDosificacion: :integer,
        NroRentaRecibo: :string,
        MontoCreditoFiscal: :double,
        CodigoAutorizacion: :string,
        CodigoControl: :string,
        NitFacturar: :string,
        NombreFacturar: :string,
        Transaccion: :string)
  end

  soap_action 'datosTransaccion',
              args: {
                datos: WsTransaccion,
                user: :string,
                password: :string
              },
              return: {
                RespTransaccion: {
                  CodError: :integer,
                  Descripcion: :string
                }
              },
              to: :datos_transaccion

  def datos_transaccion
    logger.info ap(request.env['wash_out.soap_data'])
    logger.info ap(params)

    if authenticate_webservice?(params[:user], params[:password])
      logger.info(ap(params[:datos][:CodigoRecaudacion]))
      code_recaudacion = params[:datos][:CodigoRecaudacion] rescue -1
      order = Spree::Order.find_payment_recaudacion(code_recaudacion)
      logger.info(order)
      unless order.nil?
        ############################### TOMAR TODOS LOS DATOS NECESARIOS
        data = { payed_date: (params[:datos][:Fecha].to_s rescue nil),
                 origen_transaccion: (params[:datos][:OrigenTransaccion].to_s rescue nil),
                 pais: (params[:datos][:Pais].to_s rescue nil),
                 departamento: (params[:datos][:Departamento].to_s rescue nil),
                 ciudad: (params[:datos][:Ciudad].to_s rescue nil),
                 entidad: (params[:datos][:Entidad].to_s rescue nil),
                 agencia: (params[:datos][:Agencia].to_s rescue nil),
                 operador: (params[:datos][:Operador].to_s rescue nil),
                 codigo_autorizacion: (params[:datos][:CodigoAutorizacion].to_s rescue nil),
                 codigo_control: (params[:datos][:CodigoControl].to_s rescue nil),
                 amount_price: (params[:datos][:Monto].to_f rescue 0),
                 monto_credito_fiscal: (params[:datos][:MontoCreditoFiscal].to_f rescue 0),
                 lote_dosificacion: (params[:datos][:LoteDosificacion].to_s rescue nil),
                 nro_renta_recibo: (params[:datos][:NroRentaRecibo].to_s rescue nil),
                 nit_facturar: (params[:datos][:NitFacturar].to_s rescue nil),
                 nombre_facturar: (params[:datos][:NombreFacturar].to_s rescue nil) }
        ########################### REALIZAR EL PAGO
        if params[:datos][:Transaccion].to_s.upcase == TRANSACCION_PAGAR
          if order.can_complete?
            order.complete_pagosnet(data)
            render soap: { RespTransaccion: { CodError: '0',
                                              Descripcion: RESPONSE_MESSAGE[0] } }
          else
            render soap: { RespTransaccion: { CodError: '1',
                                              Descripcion: RESPONSE_MESSAGE[2] } }
          end
        end
        ############################ REVERTIR PAGO
        if params[:datos][:Transaccion].to_s.upcase == TRANSACCION_REVERTIR
          render soap: { RespTransaccion: { CodError: '1',
                                            Descripcion: RESPONSE_MESSAGE[4] } }
          # if order.can_revert_bill?
          #   order.revert_bill(data)
          #   render soap: { RespTransaccion: { CodError: RESPONSE_MESSAGE[0].first,
          #                                     Descripcion: RESPONSE_MESSAGE[0].second } }
          # else
          #   if cart.pagosnet_bill.nil?
          #     render soap: { RespTransaccion: { CodError: RESPONSE_MESSAGE[4].first,
          #                                       Descripcion: RESPONSE_MESSAGE[4].second } }
          #   else
          #     render soap: { RespTransaccion: { CodError: RESPONSE_MESSAGE[3].first,
          #                                       Descripcion: RESPONSE_MESSAGE[3].second } }
          #   end
          # end
        end
        if params[:datos][:Transaccion].to_s.blank?
          render soap: { RespTransaccion: { CodError: '1',
                                            Descripcion: RESPONSE_MESSAGE[6] } }
        end
        #############################################
      else
        render soap: { RespTransaccion: { CodError: '1',
                                          Descripcion: RESPONSE_MESSAGE[1] } }
      end
    else
      render soap: { RespTransaccion: { CodError: '1',
                                        Descripcion: RESPONSE_MESSAGE[5] } }
    end
  end

  private

  def authenticate_webservice?(name, password)
    name.to_s.downcase == USER_WEB_SERVICE.downcase && password.to_s.downcase == PASSWORD_WEB_SERVICE.downcase
  end
end
