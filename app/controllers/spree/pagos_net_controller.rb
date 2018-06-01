module Spree
  class PagosNetController < Spree::OrdersController
    before_action :set_order, only: [:credit_card]

    def credit_card
      render 'spree/pagos_net/index'
    end

    private

    def set_order
      debugger
      @order = Spree::Order.find(params['id'].to_i)
    end
  end
end
