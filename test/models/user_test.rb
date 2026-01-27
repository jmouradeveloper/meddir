require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "current_plan returns free plan when no subscription" do
    user = User.create!(
      email_address: "newuser@example.com",
      password: "password123"
    )
    assert_equal plans(:free), user.current_plan
  end

  test "current_plan returns subscribed plan when subscription exists" do
    user = User.create!(
      email_address: "subscriber@example.com",
      password: "password123"
    )
    user.create_subscription!(plan: plans(:premium), billing_cycle: "monthly", status: "active")
    assert_equal plans(:premium), user.current_plan
  end

  test "can_create_folder? returns true when under limit" do
    user = User.create!(
      email_address: "nofolder@example.com",
      password: "password123"
    )
    assert_equal 0, user.medical_folders.count
    assert user.can_create_folder?
  end

  test "can_create_folder? returns false when at limit" do
    user = User.create!(
      email_address: "folderuser@example.com",
      password: "password123"
    )
    # Free plan has limit of 3 folders
    3.times do |i|
      user.medical_folders.create!(name: "Folder #{i}", specialty: "general")
    end
    assert_not user.can_create_folder?
  end

  test "can_share? returns false for free plan" do
    user = User.create!(
      email_address: "freeuser@example.com",
      password: "password123"
    )
    assert_not user.can_share?
  end

  test "can_share? returns true for premium plan" do
    user = User.create!(
      email_address: "premiumuser@example.com",
      password: "password123"
    )
    user.create_subscription!(plan: plans(:premium), billing_cycle: "monthly", status: "active")
    assert user.can_share?
  end

  test "storage_used_mb returns 0 when no documents" do
    user = User.create!(
      email_address: "nodocs@example.com",
      password: "password123"
    )
    assert_equal 0.0, user.storage_used_mb
  end
end
