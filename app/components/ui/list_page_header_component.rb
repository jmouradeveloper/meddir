# frozen_string_literal: true

module Ui
  class ListPageHeaderComponent < ViewComponent::Base
    def initialize(title:, subtitle: nil, action_text: nil, action_href: nil, action_icon: :plus)
      @title = title
      @subtitle = subtitle
      @action_text = action_text
      @action_href = action_href
      @action_icon = action_icon
    end

    erb_template <<~ERB
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-white"><%= @title %></h1>
          <% if @subtitle.present? %>
            <p class="text-slate-400 mt-1"><%= @subtitle %></p>
          <% end %>
        </div>
        <% if @action_text && @action_href %>
          <%= render Ui::ButtonComponent.new(href: @action_href, icon: @action_icon) do %>
            <%= @action_text %>
          <% end %>
        <% end %>
      </div>
    ERB
  end
end
