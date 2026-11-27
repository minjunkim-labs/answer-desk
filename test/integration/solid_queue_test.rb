require "test_helper"

# ADR 0002: 큐 테이블은 앱과 같은 PostgreSQL(같은 연결)에 둔다.
class SolidQueueTest < ActiveSupport::TestCase
  class NoopJob < ApplicationJob
    self.queue_adapter = :solid_queue

    def perform; end
  end

  test "Solid Queue가 앱과 같은 데이터베이스를 쓴다" do
    assert_equal ActiveRecord::Base.connection_db_config.name, SolidQueue::Job.connection_db_config.name
    assert_equal ActiveRecord::Base.connection_pool, SolidQueue::Job.connection_pool
  end

  test "작업을 넣으면 앱 데이터베이스의 solid_queue_jobs에 행이 생긴다" do
    assert_difference -> { SolidQueue::Job.count }, 1 do
      NoopJob.perform_later
    end
  end
end
