require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "should create plan with valid attributes" do
    plan = Plan.new(
      name: "Test Plan",
      slug: "test-plan-unique",
      storage_limit_mb: 100,
      folders_limit: 5,
      sharing_enabled: true,
      active_links_limit: 10,
      link_access_limit: 50,
      monthly_price: 9.99,
      annual_price: 99.99
    )
    assert plan.valid?
  end

  test "should require name" do
    plan = Plan.new(slug: "test-no-name")
    assert_not plan.valid?
    assert plan.errors[:name].any?
  end

  test "should require unique slug" do
    plan2 = Plan.new(name: "Plan 2", slug: "free")  # free exists in fixtures
    assert_not plan2.valid?
  end

  test "unlimited_storage? returns true when storage_limit_mb is nil" do
    plan = Plan.new(storage_limit_mb: nil)
    assert plan.unlimited_storage?
  end

  test "unlimited_storage? returns false when storage_limit_mb is set" do
    plan = Plan.new(storage_limit_mb: 100)
    assert_not plan.unlimited_storage?
  end

  test "unlimited_folders? returns true when folders_limit is nil" do
    plan = Plan.new(folders_limit: nil)
    assert plan.unlimited_folders?
  end

  test "unlimited_links? returns true when active_links_limit is nil" do
    plan = Plan.new(active_links_limit: nil)
    assert plan.unlimited_links?
  end

  test "free? returns true for free slug" do
    plan = Plan.new(slug: "free")
    assert plan.free?
  end

  test "free? returns false for other slugs" do
    plan = Plan.new(slug: "premium")
    assert_not plan.free?
  end
end
