
module Spree
  class ProductImport < ActiveRecord::Base
    belongs_to :user, class_name: Spree.user_class.to_s
    enum status: %i[pending success failed]
  end
end
