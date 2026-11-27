require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "up responds with 200" do
    get rails_health_check_path

    assert_response :success
  end
end
