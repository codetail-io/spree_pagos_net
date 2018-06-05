module Spree
  class PagosNetController < Spree::OrdersController
    before_action :set_order, only: [:credit_card, :cash_payment, :ebaking]

    def credit_card
      if @order
        @pagos_net_bill = @order.pagos_net_bill
        debugger
        render 'spree/pagos_net/credit_card'
      end
    end


    def cash_payment
      if @order
        @pagos_net_bill = @order.pagos_net_bill
        render 'spree/pagos_net/cash_payment'
      end
    end

    def ebaking
      if @order
        @pagos_net_bill = @order.pagos_net_bill
        render 'spree/pagos_net/ebaking'
      end
    end

    private

    def set_order
      @order = Spree::Order.find(params['id'].to_i) rescue nil
    end
  end
end
