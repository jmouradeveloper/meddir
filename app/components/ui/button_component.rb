# frozen_string_literal: true

module Ui
  class ButtonComponent < ViewComponent::Base
    VARIANTS = {
      primary: "bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white font-semibold shadow-lg shadow-emerald-500/20 transform hover:scale-105",
      secondary: "bg-slate-700/50 hover:bg-slate-700 text-slate-300 hover:text-white",
      danger: "bg-red-500/10 hover:bg-red-500/20 text-red-400 hover:text-red-300 border border-red-500/30",
      ghost: "text-slate-400 hover:text-white hover:bg-slate-700/50"
    }.freeze

    SIZES = {
      sm: "px-3 py-1.5 text-sm",
      md: "px-4 py-2",
      lg: "px-6 py-3"
    }.freeze

    def initialize(
      variant: :primary,
      size: :md,
      icon: nil,
      icon_position: :left,
      href: nil,
      method: nil,
      turbo_confirm: nil,
      type: "button",
      classes: "",
      **options
    )
      @variant = variant.to_sym
      @size = size.to_sym
      @icon = icon
      @icon_position = icon_position.to_sym
      @href = href
      @method = method
      @turbo_confirm = turbo_confirm
      @type = type
      @classes = classes
      @options = options
    end

    def call
      if @href && @method
        button_to_tag { button_content }
      elsif @href
        link_tag { button_content }
      else
        button_tag { button_content }
      end
    end

    private

    def button_content
      safe_join([
        icon_tag(:left),
        content,
        icon_tag(:right)
      ].compact)
    end

    def icon_tag(position)
      return nil unless @icon && @icon_position == position

      render Ui::IconComponent.new(name: @icon, size: :sm)
    end

    def base_classes
      [
        "flex items-center gap-2 rounded-xl transition-all",
        VARIANTS[@variant],
        SIZES[@size],
        @classes
      ].join(" ")
    end

    def link_tag(&block)
      link_to(@href, class: base_classes, **@options, &block)
    end

    def button_tag(&block)
      tag.button(type: @type, class: base_classes, **@options, &block)
    end

    def button_to_tag(&block)
      button_to(
        @href,
        method: @method,
        data: turbo_data,
        class: base_classes,
        **@options,
        &block
      )
    end

    def turbo_data
      return {} unless @turbo_confirm

      { turbo_confirm: @turbo_confirm }
    end
  end
end
