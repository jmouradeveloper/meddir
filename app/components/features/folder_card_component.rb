# frozen_string_literal: true

module Features
  class FolderCardComponent < ViewComponent::Base
    def initialize(folder:)
      @folder = folder
    end

    def call
      link_to helpers.medical_folder_path(@folder), class: link_classes do
        safe_join([folder_header, folder_description].compact)
      end
    end

    private

    def link_classes
      "group block bg-slate-800/30 hover:bg-slate-800/60 border border-slate-700/50 hover:border-#{@folder.specialty_color}-500/50 rounded-2xl p-5 transition-all duration-300"
    end

    def folder_header
      tag.div(class: "flex items-start justify-between") do
        safe_join([
          folder_info,
          document_count
        ])
      end
    end

    def folder_info
      tag.div(class: "flex items-center gap-4") do
        safe_join([
          folder_icon,
          folder_text
        ])
      end
    end

    def folder_icon
      tag.div(class: "w-12 h-12 rounded-xl bg-gradient-to-br from-#{@folder.specialty_color}-500/20 to-#{@folder.specialty_color}-600/20 flex items-center justify-center group-hover:from-#{@folder.specialty_color}-500/30 group-hover:to-#{@folder.specialty_color}-600/30 transition-all") do
        render Ui::IconComponent.new(name: :folder, size: :lg, color: "#{@folder.specialty_color}-400")
      end
    end

    def folder_text
      tag.div do
        safe_join([
          tag.h3(@folder.name, class: "text-lg font-semibold text-white group-hover:text-#{@folder.specialty_color}-400 transition-colors"),
          tag.p(@folder.specialty_name, class: "text-sm text-slate-400")
        ])
      end
    end

    def document_count
      tag.div(class: "flex items-center gap-2 text-slate-400") do
        safe_join([
          render(Ui::IconComponent.new(name: :document, size: :sm)),
          tag.span(@folder.documents_count, class: "text-sm")
        ])
      end
    end

    def folder_description
      return nil unless @folder.description.present?

      tag.p(@folder.description, class: "mt-3 text-sm text-slate-500 line-clamp-2")
    end
  end
end
