module Spree
  CheckoutController.class_eval do
    before_action :set_type_pagos_net, only: [:update]
    # before_action :set_order_net, only: [:update]
    before_action :set_payment_method_net, only: [:update]

    def update
      if @type_pagos_net
        pagos_net = PagosNet.new(@payment_method_p.id)
        user = { 'id' => @order.user.id,
                 'fiscal_name' => params['name_invoice'],
                 'ci' => params['ci_invoice'],
                 'email' => "user_ts_#{@order.user.id}@gmail.com" }
        rspn = pagos_net.create_transaction(@order.number,
                                            @order.total,
                                            user,
                                            @type_pagos_net)
        rspn_pagosnet = { 'status' => rspn.body[:registro_plan_response][:return][:codigo_error],
                          'message' => rspn.body[:registro_plan_response][:return][:descripcion_error],
                          'id_transaccion' => rspn.body[:registro_plan_response][:return][:id_transaccion] }
        logger.info(rspn_pagosnet)
        if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
          @order.temporary_address = !params[:save_user_address]
          @order.payments.last.started_processing
          if @order.completed?
            @current_order = nil
            flash.notice = Spree.t(:order_processed_successfully)
            flash['order_completed'] = true
            redirect_to completion_route
          else
            @current_order = nil
            @order.completed_at = Time.new.zone
            @order.update!
            redirect_to completion_route
            # redirect_to checkout_state_path(@order.state)
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
