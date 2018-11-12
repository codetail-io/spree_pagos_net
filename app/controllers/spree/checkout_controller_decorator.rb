module Spree
  CheckoutController.class_eval do
    before_action :set_type_pagos_net, only: [:update]
    # before_action :set_order_net, only: [:update]
    before_action :set_payment_method_net, only: [:update]

    def update
      @message_pn = nil
      if @type_pagos_net
        (@type_pagos_net = '3') if !Rails.env.production? && @type_pagos_net == '2'
        pagos_net = PagosNet.new(@payment_method_p.id)
        user = { 'id' => @order.user.id,
                 'fiscal_name' => params['name_invoice'],
                 'ci' => params['ci_invoice'],
                 'email' => "user_ts_#{@order.user.id}@gmail.com" }
        rspn = pagos_net.create_transaction(@order.number, @order.total, user, @type_pagos_net)
        rspn_pagosnet = { 'status' => rspn.body[:registro_plan_response][:return][:codigo_error],
                          'message' => rspn.body[:registro_plan_response][:return][:descripcion_error],
                          'id_transaccion' => rspn.body[:registro_plan_response][:return][:id_transaccion] }
        # if Rails.env.development? && !rspn_pagosnet['status'].to_i.zero?
        #   rspn_pagosnet = { 'status' => '0',
        #                     'message' => 'Validado hard core',
        #                     'id_transaccion' => @order.number + '_transaction' }
        # end
        @message_pn = rspn_pagosnet['message']
        if rspn_pagosnet['status'].to_i.zero?
          # save calculator-line-tushop of products
          @order.save_calculator_line_tushop
          # save pagos_net_bill
          @order.pagos_net_bill = PagosNetBill.create(transaction_id: rspn_pagosnet['id_transaccion'],
                                                      type_method: params['type_pagos_net'],
                                                      code_recaudacion: @order.number,
                                                      nombre_facturar: user['fiscal_name'],
                                                      nit_facturar: user['ci'],
                                                      status: 'processing')
          # send pagos_net items descriptions
          @order.create_items_pagosnet(@payment_method_p.id)
          #
          if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
            @order.temporary_address = !params[:save_user_address]
            @order.payments.last.started_processing!
            @order.payments.last.pend
            payment_state = @order.payments.last.state
            if @order.completed?
              @current_order = nil
              flash.notice = Spree.t(:order_processed_successfully)
              flash['order_completed'] = true
              redirect_to completion_route
            else
              @order.update_columns(payment_state: payment_state, completed_at: Time.current)
              if @type_pagos_net.to_i == 2 || @type_pagos_net.to_i == 3
                redirect_to controller: 'pagos_net', action: 'credit_card', id: @order.id
              else
                redirect_to controller: 'pagos_net', action: 'cash_payment', id: @order.id
                # redirect_to completion_route
              end
            end
          else
            render :edit
          end
        else
          render :edit
        end
      else
        if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
          @order.temporary_address = !params[:save_user_address]
          unless @order.next
            flash[:error] = @order.errors.full_messages.join("\n")
            redirect_to(checkout_state_path(@order.state)) && return
          end

          if @order.completed?
            @current_order = nil
            flash.notice = Spree.t(:order_processed_successfully)
            flash['order_completed'] = true
            redirect_to completion_route
          else
            redirect_to checkout_state_path(@order.state)
          end
        else
          render :edit
        end
      end
    end

    private

    def set_type_pagos_net
      @type_pagos_net = if params.key?('type_pagos_net')
                          if params['type_pagos_net'] == 'credit_cart'
                            '2'
                          else
                            '1'
                          end
                        end
    end

    def set_payment_method_net
      @payment_method_p = PaymentMethod.find(params['order']['payments_attributes'][0]['payment_method_id']) rescue nil
    end
  end
end
