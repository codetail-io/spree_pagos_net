module Spree
  class PagosNetController < Spree::OrdersController
    before_action :set_order, only: [:credit_card]

    def credit_card
      render 'spree/pagos_net/index' if @order
    end

    private

    def set_order
      @order = Spree::Order.find(params['id'].to_i) rescue nil
    end
  end
end
