# frozen_string_literal: true

module Imports
  class ImportProductsFromCsvUseCase < UseCase
    require 'csv'

    IGNORE_LINES = 5
    COLUMN_POSITIONS = {
      name: 0,
      price: 1,
      category: 2,
      description: 3 
    }

    arguments :file, :product_import_id

    def persist
      import_csv
    end

    private

    def import_csv
      record_errors = []

      parsed_csv.each.with_index(1) do |row, index|
        next if product_exists?(row[COLUMN_POSITIONS[:name]])

        shipping_category = find_or_create_shipping_category('Default')
        create_product(row, index, shipping_category, record_errors)
      end

      update_product_import(record_errors)
    end

    def update_product_import(record_errors)
      if record_errors.empty?
        product_import.update(status: "success")
      else
        product_import.update(status: "failed", import_errors: record_errors)
      end
    end

    def parsed_csv
      CSV.parse(file.download.lines.drop(IGNORE_LINES).join("\r\n"), headers: true, encoding: 'UTF-8', col_sep: ",", skip_blanks: true).delete_if do |row|
        row.to_hash.values.all?(&:blank?)
      end
    end

    def create_product(row, index, shipping_category, record_errors)
      begin
        name = row[COLUMN_POSITIONS[:name]]
        Spree::Product.transaction do
          product = Spree::Product.create!(
            name: name,
            stores: Spree::Store.all,
            description: row[COLUMN_POSITIONS[:description]],
            shipping_category_id: shipping_category.id,
            available_on: Time.current,
            price: row[COLUMN_POSITIONS[:price]]
          )

          product.master.stock_items.first.update!(count_on_hand: 0)
        end
      rescue ActiveRecord::RecordInvalid => exception
        record_errors.push({ row_index: index, error_info: exception.record.errors.messages })
      end
    end

    def find_or_create_shipping_category(category_name)
      Spree::ShippingCategory.find_or_create_by(name: category_name)
    end

    def product_exists?(name)
      Spree::Product.where(name: name).exists?
    end

    def product_import
      @product_import ||= Spree::ProductImport.find(product_import_id)
    end
  end
end