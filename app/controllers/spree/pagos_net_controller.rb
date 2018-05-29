module Spree
  class PagosNetController < ApplicationController
    before_action :set_order, only: [:update]
    before_action :set_payment_method, only: [:update]
    before_action :set_type_pagos_net, only: [:update]

    def update
      pagos_net = PagosNet.new(@payment_method.id)
      user = { 'id' => @order.user.id,
               'fiscal_name' => params['name_invoice'],
               'ci' => params['ci_invoice'],
               'email' => "user_ts_#{ @order.user.id }@gmail.com"}
      rspn = pagos_net.create_transaction(@order.number,
                                          @order.total,
                                          user,
                                          @type_pagos_net)
      rspn_pagosnet = { 'status' => rspn.body[:registro_plan_response][:return][:codigo_error],
                        'message' => rspn.body[:registro_plan_response][:return][:descripcion_error],
                        'id_transaccion' => rspn.body[:registro_plan_response][:return][:id_transaccion] }
      #   @payment_method = PaymentMethod.find params[:payment_method_id]
      #   data = JSON.parse Base64.strict_decode64 params[:data]
      #   render text: "Bad signature\n", status: 401 and return unless @payment_method.check_signature params[:data], params[:signature]
      #   @order = Order.find data['order_id']
      #
      #   raise ArgumentError unless @order.payments.completed.empty? &&
      #     data['currency'] == @order.currency &&
      #     BigDecimal(data['amount']) == @order.total &&
      #     data['type'] == 'buy' &&
      #     (data['status'] == 'success' || (@payment_method.preferred_test_mode && data['status'] == 'sandbox'))
      #
      #   payment = @order.payments.create amount: @order.total, payment_methods: @payment_method
      #   payment.complete!
      #
      #   render text: "Thank you.\n"
    end

    private

    def set_order
      @order = Spree::Order.find(params['order_id'])
    end

    def set_payment_method
      @payment_method = PaymentMethod.find(params['order']['payments_attributes'][0]['payment_method_id'])
    end

    def set_type_pagos_net
      @type_pagos_net = if params['type_pagos_net'] == 'credit_cart'
                          '2'
                        else
                          '1'
                        end
    end
  end
end
