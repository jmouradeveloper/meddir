# frozen_string_literal: true

module Ui
  class FormPageComponent < ViewComponent::Base
    def initialize(title:, subtitle:, icon:, icon_color: "emerald", back_href:, back_text:)
      @title = title
      @subtitle = subtitle
      @icon = icon.to_sym
      @icon_color = icon_color
      @back_href = back_href
      @back_text = back_text
    end

    erb_template <<~ERB
      <%= render Ui::BackLinkComponent.new(href: @back_href, text: @back_text) %>

      <div class="max-w-2xl mx-auto">
        <%= render Ui::CardComponent.new(classes: "p-8") do %>
          <div class="flex items-center gap-4 mb-8">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-<%= @icon_color %>-500/20 to-<%= @icon_color %>-600/20 flex items-center justify-center">
              <%= render Ui::IconComponent.new(name: @icon, size: :lg, color: "\#{@icon_color}-400") %>
            </div>
            <div>
              <h1 class="text-2xl font-bold text-white"><%= @title %></h1>
              <p class="text-slate-400"><%= @subtitle %></p>
            </div>
          </div>

          <%= content %>
        <% end %>
      </div>
    ERB
  end
end
