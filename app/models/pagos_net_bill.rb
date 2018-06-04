class PagosNetBill < ApplicationRecord
  belongs_to :order, class_name: 'Spree::Order'
end
