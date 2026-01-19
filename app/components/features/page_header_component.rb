# frozen_string_literal: true

module Features
  class PageHeaderComponent < ViewComponent::Base
    renders_one :actions

    def initialize(title:, subtitle: nil, icon: nil, icon_color: "emerald")
      @title = title
      @subtitle = subtitle
      @icon = icon
      @icon_color = icon_color
    end

    def call
      render Ui::CardComponent.new(classes: "mb-6") do
        safe_join([
          header_content,
          additional_content
        ].compact)
      end
    end

    private

    def header_content
      tag.div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4") do
        safe_join([
          title_section,
          actions_section
        ].compact)
      end
    end

    def title_section
      tag.div(class: "flex items-center gap-4") do
        safe_join([
          icon_element,
          text_section
        ].compact)
      end
    end

    def icon_element
      return nil unless @icon

      tag.div(class: "w-14 h-14 rounded-xl bg-gradient-to-br from-#{@icon_color}-500/20 to-#{@icon_color}-600/20 flex items-center justify-center") do
        render Ui::IconComponent.new(name: @icon, size: :xl, color: "#{@icon_color}-400")
      end
    end

    def text_section
      tag.div do
        safe_join([
          tag.h1(@title, class: "text-2xl font-bold text-white"),
          @subtitle ? tag.p(@subtitle, class: "text-slate-400") : nil
        ].compact)
      end
    end

    def actions_section
      return nil unless actions?

      tag.div(class: "flex items-center gap-3") do
        actions
      end
    end

    def additional_content
      return nil unless content.present?

      tag.div(class: "mt-4 pt-4 border-t border-slate-700/50") do
        content
      end
    end
  end
end
