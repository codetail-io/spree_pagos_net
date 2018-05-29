module Spree
  class PagosNetController < ApplicationController
    before_action :set_order, only: [:update]
    before_action :set_payment_method, only: [:update]

    def update
      debugger
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
  end

  private

  def set_order
    @order = Spree::Order.find(params['order_id'])
  end

  def set_payment_method
    @payment_method = PaymentMethod.find(params['order']['payments_attributes'][0]['payment_method_id'])
  end
end
