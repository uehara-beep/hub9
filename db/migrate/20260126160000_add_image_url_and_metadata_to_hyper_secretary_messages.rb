class AddImageUrlAndMetadataToHyperSecretaryMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :hyper_secretary_messages, :image_url, :string
    add_column :hyper_secretary_messages, :metadata, :jsonb
  end
end
