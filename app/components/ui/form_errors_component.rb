# frozen_string_literal: true

module Ui
  class FormErrorsComponent < ViewComponent::Base
    def initialize(record:)
      @record = record
    end

    def render?
      @record.errors.any?
    end

    erb_template <<~ERB
      <div class="bg-red-500/10 border border-red-500/50 rounded-xl p-4 mb-6">
        <div class="flex items-center gap-2 text-red-400 mb-2">
          <%= render Ui::IconComponent.new(name: :exclamation_circle, size: :md) %>
          <span class="font-medium"><%= I18n.t('components.form_errors.title') %></span>
        </div>
        <ul class="list-disc list-inside text-red-300 text-sm space-y-1">
          <% @record.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    ERB
  end
end
