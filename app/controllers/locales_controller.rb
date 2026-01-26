# frozen_string_literal: true

class LocalesController < ApplicationController
  allow_unauthenticated_access

  def update
    locale = params[:locale]

    if valid_locale?(locale)
      # Set cookie for all users (including visitors)
      set_locale_cookie(locale)

      # Update user preference if logged in
      if current_user
        current_user.update(locale: locale)
      end
    end

    redirect_back fallback_location: root_path, allow_other_host: false
  end
end
