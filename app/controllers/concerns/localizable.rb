# frozen_string_literal: true

module Localizable
  extend ActiveSupport::Concern

  AVAILABLE_LOCALES = %w[en pt-BR].freeze
  COOKIE_KEY = :locale
  COOKIE_EXPIRY = 1.year

  included do
    around_action :switch_locale
    helper_method :available_locales, :current_locale_name
  end

  private

  def switch_locale(&action)
    locale = determine_locale
    I18n.with_locale(locale, &action)
  end

  def determine_locale
    # Priority order:
    # 1. URL parameter (for switching)
    # 2. Logged-in user's preference (database)
    # 3. Cookie (for visitors)
    # 4. Browser Accept-Language header
    # 5. Default locale

    locale_from_params ||
      locale_from_user ||
      locale_from_cookie ||
      locale_from_browser ||
      I18n.default_locale
  end

  def locale_from_params
    params[:locale] if valid_locale?(params[:locale])
  end

  def locale_from_user
    return nil unless respond_to?(:current_user, true) && current_user&.locale.present?

    current_user.locale if valid_locale?(current_user.locale)
  end

  def locale_from_cookie
    cookies[COOKIE_KEY] if valid_locale?(cookies[COOKIE_KEY])
  end

  def locale_from_browser
    browser_locales = extract_browser_locales
    browser_locales.find { |locale| valid_locale?(locale) }
  end

  def extract_browser_locales
    return [] unless request.env["HTTP_ACCEPT_LANGUAGE"].present?

    request.env["HTTP_ACCEPT_LANGUAGE"]
      .split(",")
      .map { |lang| lang.split(";").first&.strip }
      .compact
      .map { |lang| normalize_locale(lang) }
  end

  def normalize_locale(locale)
    # Handle variations like pt-br, pt_BR, PT-BR
    normalized = locale.to_s.tr("_", "-")

    # Check for exact match first
    return normalized if AVAILABLE_LOCALES.include?(normalized)

    # Check case-insensitive match
    found = AVAILABLE_LOCALES.find { |l| l.downcase == normalized.downcase }
    return found if found

    # Check language-only match (e.g., "pt" matches "pt-BR")
    language = normalized.split("-").first
    AVAILABLE_LOCALES.find { |l| l.split("-").first.downcase == language.downcase }
  end

  def valid_locale?(locale)
    return false if locale.blank?

    AVAILABLE_LOCALES.include?(locale.to_s) ||
      AVAILABLE_LOCALES.any? { |l| l.downcase == locale.to_s.downcase }
  end

  def set_locale_cookie(locale)
    cookies[COOKIE_KEY] = {
      value: locale,
      expires: COOKIE_EXPIRY.from_now,
      httponly: true,
      same_site: :lax
    }
  end

  def available_locales
    AVAILABLE_LOCALES.map do |locale|
      {
        code: locale,
        name: I18n.t("locales.#{locale}", locale: locale),
        current: I18n.locale.to_s == locale
      }
    end
  end

  def current_locale_name
    I18n.t("locales.#{I18n.locale}")
  end
end
