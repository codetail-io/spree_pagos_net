module Spree
  class PagosNetController < Spree::OrdersController
    before_action :set_order, only: [:credit_card]

    def credit_card
      render 'spree/pagos_net/credit_card' if @order
    end

    def cash_payment
      render 'spree/pagos_net/cash_payment' if @order
    end

    private

    def set_order
      @order = Spree::Order.find(params['id'].to_i) rescue nil
    end
  end
end
