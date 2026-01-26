class Document < ApplicationRecord
  belongs_to :medical_folder

  has_one_attached :file

  validates :title, presence: true, length: { minimum: 2, maximum: 200 }
  validates :file, presence: true

  scope :recent, -> { order(document_date: :desc, created_at: :desc) }

  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    image/jpeg
    image/png
    image/gif
    image/webp
    application/dicom
  ].freeze

  def file_type
    return nil unless file.attached?

    content_type = file.content_type
    case content_type
    when /pdf/
      :pdf
    when /image/
      :image
    when /dicom/
      :dicom
    else
      :other
    end
  end

  def file_size_mb
    return nil unless file.attached?

    (file.byte_size / 1_000_000.0).round(2)
  end

  def formatted_date
    return I18n.t("common.messages.no_date") unless document_date

    I18n.l(document_date, format: :long)
  end

  def user
    medical_folder.user
  end
end
