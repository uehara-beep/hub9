class Hub::SecretaryController < ApplicationController
  def show
    @messages = HyperSecretaryMessage.order(created_at: :asc).last(80)
  end
end
