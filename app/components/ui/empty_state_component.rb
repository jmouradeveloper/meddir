# frozen_string_literal: true

module Ui
  class EmptyStateComponent < ViewComponent::Base
    def initialize(title:, description:, icon: :document, action_text: nil, action_href: nil)
      @title = title
      @description = description
      @icon = icon
      @action_text = action_text
      @action_href = action_href
    end

    erb_template <<~ERB
      <%= render Ui::CardComponent.new(variant: :subtle, classes: "p-12 text-center") do %>
        <div class="w-16 h-16 rounded-2xl bg-slate-700/50 flex items-center justify-center mx-auto mb-4">
          <%= render Ui::IconComponent.new(name: @icon, size: :xxl, color: "slate-500") %>
        </div>
        <h3 class="text-lg font-semibold text-white mb-2"><%= @title %></h3>
        <p class="text-slate-400 mb-6"><%= @description %></p>
        <% if @action_text && @action_href %>
          <%= render Ui::ButtonComponent.new(href: @action_href, icon: :plus, size: :lg) do %>
            <%= @action_text %>
          <% end %>
        <% end %>
      <% end %>
    ERB
  end
end
