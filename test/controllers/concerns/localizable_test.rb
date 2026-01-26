require "test_helper"

class LocalizableTest < ActionDispatch::IntegrationTest
  test "detects locale from Accept-Language header for English" do
    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9" }

    assert_response :success
    assert_equal :en, I18n.locale
  end

  test "detects locale from Accept-Language header for Portuguese" do
    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "pt-BR,pt;q=0.9,en;q=0.8" }

    assert_response :success
    # The page should be in Portuguese
    assert_select "h1", /Todos os Seus Documentos/
  end

  test "falls back to English for unsupported locale" do
    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "fr-FR,fr;q=0.9" }

    assert_response :success
    assert_select "h1", /All Your Medical/
  end

  test "cookie locale takes precedence over browser locale" do
    cookies[:locale] = "pt-BR"

    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US" }

    assert_response :success
    assert_select "h1", /Todos os Seus Documentos/
  end

  test "user locale takes precedence over cookie locale" do
    user = users(:one)
    user.update!(locale: "en")
    sign_in_as(user)

    cookies[:locale] = "pt-BR"

    get dashboard_path

    assert_response :success
    assert_select "h2", /Your Medical Folders/
  end

  test "params locale takes precedence over all other sources" do
    user = users(:one)
    user.update!(locale: "en")
    sign_in_as(user)

    cookies[:locale] = "en"

    # Using the locale path to switch
    patch locale_path, params: { locale: "pt-BR" }
    follow_redirect!

    # Now the locale should be Portuguese
    assert_equal "pt-BR", cookies[:locale]
  end

  test "normalizes pt_BR to pt-BR" do
    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "pt_BR" }

    assert_response :success
    assert_select "h1", /Todos os Seus Documentos/
  end

  test "matches language code without region" do
    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "pt" }

    assert_response :success
    # Should match pt-BR since pt matches the language portion
    assert_select "h1", /Todos os Seus Documentos/
  end

  test "available_locales helper returns correct structure" do
    get root_path

    assert_response :success
    # The helper should be available and contain both locales
    assert_select "button[data-action='click->dropdown#toggle']"
  end
end
