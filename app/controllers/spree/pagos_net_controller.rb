module Spree
  class PagosNetController < Spree::OrdersController
    before_action :set_order, only: [:credit_card]

    def credit_card
      render 'spree/pagos_net/credit_card' if @order
    end

    def cash_payment
      if @order
        @pnb = @order.pagos_net_bills
        render 'spree/pagos_net/cash_payment'
      end

    end

    private

    def set_order
      @order = Spree::Order.find(params['id'].to_i) rescue nil
    end
  end
end
