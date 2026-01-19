# frozen_string_literal: true

module Ui
  class BackLinkComponent < ViewComponent::Base
    def initialize(href:, text:)
      @href = href
      @text = text
    end

    erb_template <<~ERB
      <div class="mb-6">
        <%= link_to @href, class: "inline-flex items-center gap-2 text-slate-400 hover:text-white transition-colors" do %>
          <%= render Ui::IconComponent.new(name: :arrow_left, size: :md) %>
          <%= @text %>
        <% end %>
      </div>
    ERB
  end
end
