require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  # ============================================
  # Cookie Management Tests
  # ============================================

  test "update sets locale cookie for unauthenticated user" do
    patch locale_path, params: { locale: "pt-BR" }

    assert_redirected_to root_path
    assert_equal "pt-BR", cookies[:locale]
  end

  test "update sets English locale cookie" do
    cookies[:locale] = "pt-BR"

    patch locale_path, params: { locale: "en" }

    assert_redirected_to root_path
    assert_equal "en", cookies[:locale]
  end

  test "update with invalid locale does not set cookie" do
    patch locale_path, params: { locale: "invalid-locale" }

    assert_redirected_to root_path
    assert_nil cookies[:locale]
  end

  test "update with empty locale does not set cookie" do
    patch locale_path, params: { locale: "" }

    assert_redirected_to root_path
    assert_nil cookies[:locale]
  end

  test "update with nil locale does not set cookie" do
    patch locale_path, params: {}

    assert_redirected_to root_path
    assert_nil cookies[:locale]
  end

  # ============================================
  # Authenticated User Tests
  # ============================================

  test "update redirects for authenticated user" do
    sign_in_as(users(:one))

    patch locale_path, params: { locale: "pt-BR" }

    assert_response :redirect
  end

  # ============================================
  # Redirect Behavior Tests
  # ============================================

  test "update redirects back to previous page when referer is present" do
    sign_in_as(users(:one))

    patch locale_path, params: { locale: "pt-BR" }, headers: { "HTTP_REFERER" => dashboard_url }

    assert_redirected_to dashboard_url
  end

  test "update redirects to root when no referer" do
    patch locale_path, params: { locale: "pt-BR" }

    assert_redirected_to root_path
  end

  test "update does not redirect to external hosts" do
    patch locale_path, params: { locale: "pt-BR" }, headers: { "HTTP_REFERER" => "https://evil.com/malicious" }

    assert_redirected_to root_path
  end

  # ============================================
  # Case Sensitivity Tests
  # ============================================

  test "update with exact locale match works" do
    patch locale_path, params: { locale: "pt-BR" }

    assert_redirected_to root_path
    assert_equal "pt-BR", cookies[:locale]
  end
end
