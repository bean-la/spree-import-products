class CreateProductsFromCsvJob < ApplicationJob
  queue_as :default

  def perform(product_import)
    return if product_import.csv_file.blank?

    Imports::ImportProductsFromCsvUseCase.call(
      params: {
        product_import_id: product_import.id
      }
    )
  end
end