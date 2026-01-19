# frozen_string_literal: true

module Ui
  class CardComponent < ViewComponent::Base
    VARIANTS = {
      default: "bg-slate-800/50 backdrop-blur-xl rounded-2xl border border-slate-700/50",
      subtle: "bg-slate-800/30 border border-slate-700/50 rounded-2xl",
      interactive: "bg-slate-800/30 hover:bg-slate-800/60 border border-slate-700/50 rounded-xl transition-all"
    }.freeze

    def initialize(variant: :default, padding: true, classes: "", **options)
      @variant = variant.to_sym
      @padding = padding
      @classes = classes
      @options = options
    end

    def call
      tag.div(class: css_classes, **@options) do
        content
      end
    end

    private

    def css_classes
      [
        VARIANTS[@variant],
        @padding ? "p-6" : nil,
        @classes
      ].compact.join(" ")
    end
  end
end
