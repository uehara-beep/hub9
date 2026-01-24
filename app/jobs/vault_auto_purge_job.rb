class VaultAutoPurgeJob < ApplicationJob
  queue_as :default

  def perform
    VaultEntry.where("expires_at < ?", Time.current).find_each do |e|
      e.receipt.purge if e.receipt.attached?
      e.destroy!
    end

    # Clean up unattached blobs
    ActiveStorage::Blob.unattached.find_each(&:purge)
  end
end
