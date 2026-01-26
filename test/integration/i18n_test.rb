require "test_helper"

class I18nIntegrationTest < ActionDispatch::IntegrationTest
  # ============================================
  # Home Page Language Tests
  # ============================================

  test "home page renders in English by default" do
    get root_path

    assert_response :success
    assert_select "h1", /All Your Medical/
  end

  test "home page renders in Portuguese when locale cookie is set" do
    cookies[:locale] = "pt-BR"

    get root_path

    assert_response :success
    assert_select "h1", /Todos os Seus Documentos/
  end

  test "home page renders in Portuguese from Accept-Language header" do
    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "pt-BR" }

    assert_response :success
    assert_select "h1", /Todos os Seus Documentos/
  end

  # ============================================
  # Login Page Language Tests
  # ============================================

  test "login page renders in English" do
    get new_session_path

    assert_response :success
    assert_select "h1", "Welcome Back"
    assert_select "input[type='submit'][value='Sign In']"
  end

  test "login page renders in Portuguese" do
    cookies[:locale] = "pt-BR"

    get new_session_path

    assert_response :success
    assert_select "h1", "Bem-vindo de Volta"
    assert_select "input[type='submit'][value='Entrar']"
  end

  # ============================================
  # Registration Page Language Tests
  # ============================================

  test "registration page renders in English" do
    get new_registration_path

    assert_response :success
    assert_select "h1", "Create Account"
    assert_select "input[type='submit'][value='Create Account']"
  end

  test "registration page renders in Portuguese" do
    cookies[:locale] = "pt-BR"

    get new_registration_path

    assert_response :success
    assert_select "h1", "Criar Conta"
    assert_select "input[type='submit'][value='Criar Conta']"
  end

  # ============================================
  # Dashboard Language Tests
  # ============================================

  test "dashboard renders in English for logged in user" do
    sign_in_as(users(:one))

    get dashboard_path

    assert_response :success
    assert_select "h2", /Your Medical Folders/
    assert_select "span", /Stats Overview/i
  end

  test "dashboard renders in Portuguese for logged in user with Portuguese preference" do
    user = users(:one)
    user.update!(locale: "pt-BR")
    sign_in_as(user)

    get dashboard_path

    assert_response :success
    assert_select "h2", /Suas Pastas Médicas/
    assert_select "span", /Visão Geral/i
  end

  # ============================================
  # Language Selector Tests
  # ============================================

  test "language selector is visible in header for logged in users" do
    sign_in_as(users(:one))

    get dashboard_path

    assert_response :success
    assert_select "button[data-action='click->dropdown#toggle']"
  end

  test "language selector is visible on home page" do
    get root_path

    assert_response :success
    assert_select "button[data-action='click->dropdown#toggle']"
  end

  # ============================================
  # Locale Switching Flow Tests
  # ============================================

  test "switching locale persists across page loads" do
    # Start in English
    get root_path
    assert_select "h1", /All Your Medical/

    # Switch to Portuguese
    patch locale_path, params: { locale: "pt-BR" }
    follow_redirect!

    # Navigate to another page
    get new_session_path
    assert_select "h1", "Bem-vindo de Volta"

    # Navigate back to home
    get root_path
    assert_select "h1", /Todos os Seus Documentos/
  end

  test "switching locale for authenticated user persists after logout and login" do
    user = users(:one)
    sign_in_as(user)

    # Switch to Portuguese
    patch locale_path, params: { locale: "pt-BR" }

    # Logout
    delete session_path

    # Login again
    post session_path, params: { email_address: user.email_address, password: "password" }
    follow_redirect!

    # Should still be in Portuguese (from user preference)
    get dashboard_path
    assert_select "h2", /Suas Pastas Médicas/
  end

  # ============================================
  # Flash Messages Language Tests
  # ============================================

  test "flash messages are translated in English" do
    post session_path, params: { email_address: "wrong@example.com", password: "wrong" }

    assert_redirected_to new_session_path
    follow_redirect!

    assert_select ".text-red-300", /email address or password/i
  end

  test "flash messages are translated in Portuguese" do
    cookies[:locale] = "pt-BR"

    post session_path, params: { email_address: "wrong@example.com", password: "wrong" }

    assert_redirected_to new_session_path
    follow_redirect!

    assert_select ".text-red-300", /E-mail ou senha incorretos/i
  end

  # ============================================
  # Medical Folders Language Tests
  # ============================================

  test "medical folder form renders in English" do
    user = users(:one)
    user.update!(locale: "en")
    sign_in_as(user)

    get new_medical_folder_path

    assert_response :success
    # Check for English content (button text)
    assert_match(/Create Folder/i, response.body)
  end

  test "medical folder form renders in Portuguese" do
    user = users(:one)
    user.update!(locale: "pt-BR")
    sign_in_as(user)

    get new_medical_folder_path

    assert_response :success
    # Check for Portuguese content (button text)
    assert_match(/Criar Pasta/i, response.body)
  end

  test "medical folder specialties are translated in English" do
    sign_in_as(users(:one))

    get new_medical_folder_path

    assert_response :success
    assert_select "option", "Cardiology"
    assert_select "option", "General Practice"
  end

  test "medical folder specialties are translated in Portuguese" do
    user = users(:one)
    user.update!(locale: "pt-BR")
    sign_in_as(user)

    get new_medical_folder_path

    assert_response :success
    assert_select "option", "Cardiologia"
    assert_select "option", "Clínica Geral"
  end

  # ============================================
  # Available Locales Tests
  # ============================================

  test "I18n has expected available locales" do
    assert_includes I18n.available_locales, :en
    assert_includes I18n.available_locales, :"pt-BR"
  end

  test "I18n default locale is English" do
    assert_equal :en, I18n.default_locale
  end
end
