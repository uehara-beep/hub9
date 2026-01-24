require "test_helper"

class Vault::EntriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get vault_entries_index_url
    assert_response :success
  end

  test "should get new" do
    get vault_entries_new_url
    assert_response :success
  end

  test "should get create" do
    get vault_entries_create_url
    assert_response :success
  end

  test "should get show" do
    get vault_entries_show_url
    assert_response :success
  end

  test "should get destroy" do
    get vault_entries_destroy_url
    assert_response :success
  end
end
