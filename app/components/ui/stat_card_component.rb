# frozen_string_literal: true

module Ui
  class StatCardComponent < ViewComponent::Base
    def initialize(value:, label:, icon:, color: "emerald")
      @value = value
      @label = label
      @icon = icon
      @color = color
    end

    def call
      render Ui::CardComponent.new do
        tag.div(class: "flex items-center gap-4") do
          safe_join([
            icon_container,
            text_content
          ])
        end
      end
    end

    private

    def icon_container
      tag.div(class: "w-12 h-12 rounded-xl bg-gradient-to-br from-#{@color}-500/20 to-#{@color}-600/20 flex items-center justify-center") do
        render Ui::IconComponent.new(name: @icon, size: :lg, color: "#{@color}-400")
      end
    end

    def text_content
      tag.div do
        safe_join([
          tag.p(@value, class: "text-2xl font-bold text-white"),
          tag.p(@label, class: "text-slate-400 text-sm")
        ])
      end
    end
  end
end
