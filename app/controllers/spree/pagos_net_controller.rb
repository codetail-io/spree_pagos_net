module Spree
  class PagosNetController < ApplicationController
    def credit_card
      render 'spree/pagos_net/index'
    end

    private
  end
end
