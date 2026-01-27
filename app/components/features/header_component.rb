# frozen_string_literal: true

module Features
  class HeaderComponent < ViewComponent::Base
    def initialize(user:, show_logo_link: true)
      @user = user
      @show_logo_link = show_logo_link
    end

    erb_template <<~ERB
      <header class="border-b border-slate-700/50 bg-slate-900/80 backdrop-blur-xl sticky top-0 z-40">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-16">
            <% if @show_logo_link %>
              <%= link_to helpers.dashboard_path, class: "flex items-center gap-3 hover:opacity-80 transition-opacity" do %>
                <%= logo %>
              <% end %>
            <% else %>
              <div class="flex items-center gap-3">
                <%= logo %>
              </div>
            <% end %>

            <div class="flex items-center gap-4">
              <%# Language Selector %>
              <div class="relative" data-controller="dropdown">
                <button type="button"
                        data-action="click->dropdown#toggle"
                        class="flex items-center gap-2 px-3 py-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition-all">
                  <%= render Ui::IconComponent.new(name: :globe, size: :sm) %>
                  <span class="hidden sm:inline text-sm"><%= helpers.current_locale_name %></span>
                  <%= render Ui::IconComponent.new(name: :chevron_down, size: :xs) %>
                </button>
                <div data-dropdown-target="menu"
                     class="hidden absolute right-0 mt-2 w-40 bg-slate-800 border border-slate-700 rounded-xl shadow-xl z-50">
                  <div class="py-1">
                    <% helpers.available_locales.each do |locale| %>
                      <%= button_to helpers.locale_path,
                          method: :patch,
                          params: { locale: locale[:code] },
                          class: "w-full flex items-center justify-between px-4 py-2 text-sm \#{locale[:current] ? 'text-emerald-400 bg-emerald-500/10' : 'text-slate-300 hover:bg-slate-700/50'} transition-colors" do %>
                        <span><%= locale[:name] %></span>
                        <% if locale[:current] %>
                          <%= render Ui::IconComponent.new(name: :check, size: :sm, color: "emerald-400") %>
                        <% end %>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              </div>

              <span class="text-slate-400 text-sm hidden sm:block">
                <span class="text-white font-medium"><%= @user.display_name %></span>
              </span>
              <%= button_to helpers.session_path, method: :delete, class: "flex items-center gap-2 px-4 py-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition-all" do %>
                <%= render Ui::IconComponent.new(name: :logout, size: :sm) %>
                <span class="hidden sm:inline"><%= I18n.t('components.header.sign_out') %></span>
              <% end %>
            </div>
          </div>
        </div>
      </header>
    ERB

    private

    def logo
      safe_join([
        tag.div(class: "w-9 h-9 rounded-xl bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center shadow-lg shadow-emerald-500/20") do
          render Ui::IconComponent.new(name: :document, size: :md, color: "white")
        end,
        tag.span("MedDir", class: "text-lg font-bold text-white tracking-tight")
      ])
    end
  end
end
