require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "앱이 뜨면 /up이 200을 돌려준다" do
    get rails_health_check_path

    assert_response :success
  end
end
