require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "manifest.json is accessible" do
    get "/manifest.json"
    assert_response :success
    assert_equal "application/json", response.media_type

    json = JSON.parse(response.body)
    assert_equal "MedDir - Medical Records Hub", json["name"]
    assert_equal "MedDir", json["short_name"]
    assert_equal "/dashboard", json["start_url"]
    assert_equal "standalone", json["display"]
    assert json["icons"].is_a?(Array)
    assert json["icons"].length > 0
  end

  test "service-worker.js is accessible" do
    get "/service-worker.js"
    assert_response :success
    assert response.body.include?("Service Worker")
  end

  test "offline.html is accessible" do
    get "/offline.html"
    assert_response :success
    assert response.body.include?("offline")
  end

  test "PWA icons are accessible" do
    %w[72 96 128 144 152 192 384 512].each do |size|
      get "/icons/icon-#{size}x#{size}.png"
      assert_response :success, "Icon #{size}x#{size} should be accessible"
      assert_equal "image/png", response.media_type
    end
  end

  test "layout includes PWA meta tags" do
    get "/"
    assert_response :success
    assert response.body.include?('rel="manifest"')
    assert response.body.include?('name="theme-color"')
    assert response.body.include?('name="apple-mobile-web-app-capable"')
  end

  test "dashboard includes PWA install prompt for authenticated users" do
    sign_in_as users(:one)
    get "/dashboard"
    assert_response :success

    # Verify the PWA install prompt partial is rendered
    assert_select '[data-controller="pwa-install"]', 1
    assert_select '[data-pwa-install-target="container"]', 1

    # Verify configuration values are set
    assert_select '[data-pwa-install-dismiss-days-value="7"]', 1
    assert_select '[data-pwa-install-show-delay-value="1500"]', 1
  end

  test "PWA install prompt has Android install button" do
    sign_in_as users(:one)
    get "/dashboard"
    assert_response :success

    # Verify Android prompt elements exist
    assert_select '[data-pwa-install-target="androidPrompt"]', 1
    assert_select '[data-action="pwa-install#install"]', 1
    assert_select '[data-pwa-install-target="button"]', 1
  end

  test "PWA install prompt has iOS instructions" do
    sign_in_as users(:one)
    get "/dashboard"
    assert_response :success

    # Verify iOS instructions elements exist (hidden by default)
    assert_select '[data-pwa-install-target="iosInstructions"]', 1
    # iOS instructions mention "Add to Home Screen"
    assert response.body.include?("Add to Home Screen")
  end

  test "PWA install prompt has dismiss buttons" do
    sign_in_as users(:one)
    get "/dashboard"
    assert_response :success

    # Verify dismiss action buttons exist
    assert_select '[data-action="pwa-install#dismiss"]', minimum: 2
  end

  test "PWA install prompt shows app install messaging" do
    sign_in_as users(:one)
    get "/dashboard"
    assert_response :success

    # Verify install messaging is present
    assert response.body.include?("Install MedDir App")
    assert response.body.include?("quick access and offline support")
  end
end
