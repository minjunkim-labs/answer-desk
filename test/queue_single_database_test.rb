require "test_helper"

# docs/adr/0002: 큐 테이블은 앱과 같은 PostgreSQL에 둔다. 큐를 따로 연결하는 설정이 생기면 여기서 걸린다.
class QueueSingleDatabaseTest < ActiveSupport::TestCase
  class ProbeJob < ApplicationJob
    def perform; end
  end

  test "Active Job uses Solid Queue" do
    assert_equal "ActiveJob::QueueAdapters::SolidQueueAdapter", ApplicationJob.queue_adapter.class.name
  end

  test "Solid Queue shares the primary database connection pool" do
    assert_same ActiveRecord::Base.connection_pool, SolidQueue::Job.connection_pool
    assert SolidQueue::Job.table_exists?
  end

  test "an enqueued job is stored in the primary database" do
    original = ProbeJob.queue_adapter
    ProbeJob.queue_adapter = :solid_queue

    assert_difference -> { SolidQueue::Job.where(class_name: ProbeJob.name).count }, 1 do
      ProbeJob.perform_later
    end
  ensure
    ProbeJob.queue_adapter = original
  end
end
