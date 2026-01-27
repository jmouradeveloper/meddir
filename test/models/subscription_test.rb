require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)  # User without subscription
    @premium_plan = plans(:premium)
  end

  test "should create subscription with valid attributes" do
    subscription = Subscription.new(
      user: @user,
      plan: @premium_plan,
      billing_cycle: "monthly",
      status: "active"
    )
    assert subscription.valid?
  end

  test "should validate billing_cycle inclusion" do
    subscription = Subscription.new(
      user: @user,
      plan: @premium_plan,
      billing_cycle: "invalid"
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:billing_cycle], "is not included in the list"
  end

  test "should validate status inclusion" do
    subscription = Subscription.new(
      user: @user,
      plan: @premium_plan,
      status: "invalid"
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:status], "is not included in the list"
  end

  test "active? returns true for active status with no end date" do
    subscription = Subscription.new(status: "active", ends_at: nil)
    assert subscription.active?
  end

  test "active? returns true for active status with future end date" do
    subscription = Subscription.new(status: "active", ends_at: 1.day.from_now)
    assert subscription.active?
  end

  test "active? returns false for active status with past end date" do
    subscription = Subscription.new(status: "active", ends_at: 1.day.ago)
    assert_not subscription.active?
  end

  test "days_remaining returns correct count" do
    subscription = Subscription.new(ends_at: 5.days.from_now)
    assert_equal 5, subscription.days_remaining
  end

  test "days_remaining returns nil when ends_at is nil" do
    subscription = Subscription.new(ends_at: nil)
    assert_nil subscription.days_remaining
  end
end
