module Spree
  class PagosNetController < Spree::OrdersController
    def credit_card
      render 'spree/pagos_net/index'
    end

    private
  end
end
