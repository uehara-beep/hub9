require "test_helper"

class VaultControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get vault_index_url
    assert_response :success
  end
end
