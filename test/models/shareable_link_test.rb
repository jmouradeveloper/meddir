require "test_helper"

class ShareableLinkTest < ActiveSupport::TestCase
  setup do
    @medical_folder = medical_folders(:one)
  end

  test "generates token on create" do
    link = @medical_folder.shareable_links.create!
    assert_not_nil link.token
    assert_equal 43, link.token.length  # urlsafe_base64(32) generates 43 chars
  end

  test "sets active to true on create" do
    link = @medical_folder.shareable_links.create!
    assert link.active?
  end

  test "sets access_count to 0 on create" do
    link = @medical_folder.shareable_links.create!
    assert_equal 0, link.access_count
  end

  test "expired? returns true when expires_at is in the past" do
    link = ShareableLink.new(expires_at: 1.day.ago)
    assert link.expired?
  end

  test "expired? returns false when expires_at is in the future" do
    link = ShareableLink.new(expires_at: 1.day.from_now)
    assert_not link.expired?
  end

  test "expired? returns false when expires_at is nil" do
    link = ShareableLink.new(expires_at: nil)
    assert_not link.expired?
  end

  test "access_limit_reached? returns true when count equals limit" do
    link = ShareableLink.new(access_count: 10, access_limit: 10)
    assert link.access_limit_reached?
  end

  test "access_limit_reached? returns false when count is below limit" do
    link = ShareableLink.new(access_count: 5, access_limit: 10)
    assert_not link.access_limit_reached?
  end

  test "access_limit_reached? returns false when limit is nil" do
    link = ShareableLink.new(access_count: 100, access_limit: nil)
    assert_not link.access_limit_reached?
  end

  test "valid_for_access? returns true when active and not expired and not at limit" do
    link = ShareableLink.new(
      active: true,
      expires_at: 1.day.from_now,
      access_count: 5,
      access_limit: 10
    )
    assert link.valid_for_access?
  end

  test "valid_for_access? returns false when inactive" do
    link = ShareableLink.new(
      active: false,
      expires_at: 1.day.from_now,
      access_count: 0,
      access_limit: 10
    )
    assert_not link.valid_for_access?
  end

  test "valid_for_access? returns false when expired" do
    link = ShareableLink.new(
      active: true,
      expires_at: 1.day.ago,
      access_count: 0,
      access_limit: 10
    )
    assert_not link.valid_for_access?
  end

  test "valid_for_access? returns false when access limit reached" do
    link = ShareableLink.new(
      active: true,
      expires_at: 1.day.from_now,
      access_count: 10,
      access_limit: 10
    )
    assert_not link.valid_for_access?
  end

  test "increment_access! increases access_count by 1" do
    link = @medical_folder.shareable_links.create!
    assert_equal 0, link.access_count
    link.increment_access!
    assert_equal 1, link.reload.access_count
  end

  test "remaining_accesses returns correct count" do
    link = ShareableLink.new(access_count: 3, access_limit: 10)
    assert_equal 7, link.remaining_accesses
  end

  test "remaining_accesses returns nil when unlimited" do
    link = ShareableLink.new(access_count: 50, access_limit: nil)
    assert_nil link.remaining_accesses
  end
end
