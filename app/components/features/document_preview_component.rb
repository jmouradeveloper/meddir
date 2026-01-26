# frozen_string_literal: true

module Features
  class DocumentPreviewComponent < ViewComponent::Base
    def initialize(document:)
      @document = document
    end

    def render?
      @document.file.attached?
    end

    erb_template <<~ERB
      <div data-controller="fullscreen">
        <div class="bg-slate-800/50 backdrop-blur-xl rounded-2xl border border-slate-700/50 overflow-hidden">
          <div class="px-6 py-4 border-b border-slate-700/50 flex items-center justify-between">
            <h2 class="text-lg font-semibold text-white"><%= I18n.t('components.document_preview.preview') %></h2>
            <% if previewable? %>
              <button type="button"
                      data-action="click->fullscreen#open"
                      class="flex items-center gap-2 px-3 py-1.5 bg-slate-700/50 hover:bg-slate-700 text-slate-300 hover:text-white rounded-lg transition-all text-sm"
                      title="<%= I18n.t('components.document_preview.fullscreen') %>">
                <%= render Ui::IconComponent.new(name: :expand, size: :sm) %>
                <%= I18n.t('components.document_preview.fullscreen') %>
              </button>
            <% end %>
          </div>

          <div class="p-6 bg-slate-800/50">
            <%= preview_content %>
          </div>
        </div>

        <% if previewable? %>
          <%= fullscreen_modal %>
        <% end %>
      </div>
    ERB

    private

    def previewable?
      @document.file_type == :image || @document.file_type == :pdf
    end

    def preview_content
      case @document.file_type
      when :image
        image_preview
      when :pdf
        pdf_preview
      else
        unsupported_preview
      end
    end

    def image_preview
      tag.div(class: "flex justify-center") do
        helpers.image_tag(
          helpers.url_for(@document.file),
          class: "max-w-full h-auto rounded-lg shadow-lg",
          alt: @document.title
        )
      end
    end

    def pdf_preview
      tag.div(class: "aspect-[3/4] w-full h-full") do
        tag.iframe(
          src: helpers.url_for(@document.file),
          class: "w-full h-full rounded-lg",
          title: @document.title
        )
      end
    end

    def unsupported_preview
      tag.div(class: "text-center py-12") do
        safe_join([
          tag.div(class: "w-16 h-16 rounded-2xl bg-slate-700/50 flex items-center justify-center mx-auto mb-4") do
            render Ui::IconComponent.new(name: :document, size: :xxl, color: "slate-500")
          end,
          tag.p(I18n.t("components.document_preview.not_available"), class: "text-slate-400 mb-4"),
          helpers.link_to(
            helpers.rails_blob_path(@document.file, disposition: "attachment"),
            class: "inline-flex items-center gap-2 px-6 py-3 bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400 border border-emerald-500/30 rounded-xl transition-all"
          ) do
            safe_join([
              render(Ui::IconComponent.new(name: :download, size: :sm)),
              I18n.t("components.document_preview.download_to_view")
            ])
          end
        ])
      end
    end

    def fullscreen_modal
      tag.div(
        data: {
          fullscreen_target: "modal",
          action: "click->fullscreen#closeOnBackdrop"
        },
        class: "fixed inset-0 z-50 hidden opacity-0 transition-opacity duration-300 bg-slate-950/80 backdrop-blur-xl"
      ) do
        tag.div(
          data: { fullscreen_target: "modalContent" },
          class: "w-full h-full flex flex-col transition-transform duration-200 scale-95"
        ) do
          safe_join([ modal_header, modal_content ])
        end
      end
    end

    def modal_header
      tag.div(class: "flex items-center justify-between px-6 py-4 bg-slate-900/80 border-b border-slate-700/50") do
        safe_join([
          tag.h2(@document.title, class: "text-lg font-semibold text-white truncate"),
          tag.button(
            type: "button",
            data: { action: "click->fullscreen#close" },
            class: "flex items-center gap-2 px-4 py-2 bg-slate-700/50 hover:bg-slate-700 text-slate-300 hover:text-white rounded-lg transition-all"
          ) do
            safe_join([
              render(Ui::IconComponent.new(name: :close, size: :md)),
              I18n.t("common.actions.close")
            ])
          end
        ])
      end
    end

    def modal_content
      tag.div(class: "flex-1 min-h-0 p-6 flex items-center justify-center") do
        case @document.file_type
        when :image
          helpers.image_tag(
            helpers.url_for(@document.file),
            class: "max-w-full max-h-full w-auto h-auto object-contain rounded-lg shadow-2xl",
            alt: @document.title
          )
        when :pdf
          tag.iframe(
            src: helpers.url_for(@document.file),
            class: "w-full h-full rounded-lg shadow-2xl",
            title: @document.title
          )
        end
      end
    end
  end
end
