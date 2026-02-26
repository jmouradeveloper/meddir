class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :medical_folders, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_one :plan, through: :subscription

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, length: { maximum: 100 }

  def display_name
    name.presence || email_address.split("@").first.titleize
  end

  # Plan methods
  def current_plan
    plan || Plan.free
  end

  def subscribed?
    subscription.present? && subscription.active? && !current_plan.free?
  end

  # Storage calculations
  def storage_used_bytes
    Document.joins(:medical_folder)
            .where(medical_folders: { user_id: id })
            .joins(file_attachment: :blob)
            .sum("active_storage_blobs.byte_size")
  end

  def storage_used_mb
    (storage_used_bytes.to_f / 1.megabyte).round(2)
  end

  def storage_limit_mb
    current_plan.storage_limit_mb
  end

  def storage_percentage
    return 0 if current_plan.unlimited_storage?

    [ (storage_used_mb / storage_limit_mb.to_f * 100).round(1), 100 ].min
  end

  # Limit checks
  def can_create_folder?
    current_plan.unlimited_folders? || medical_folders.count < current_plan.folders_limit
  end

  def can_upload?(file_size_bytes)
    return true if current_plan.unlimited_storage?

    (storage_used_bytes + file_size_bytes) <= (current_plan.storage_limit_mb * 1.megabyte)
  end

  def can_share?
    current_plan.sharing_enabled
  end

  def can_create_shareable_link?
    return false unless can_share?
    return true if current_plan.unlimited_links?

    active_shareable_links_count < current_plan.active_links_limit
  end

  def active_shareable_links_count
    ShareableLink.joins(:medical_folder)
                 .where(medical_folders: { user_id: id })
                 .active
                 .count
  end

  def folders_count
    medical_folders.count
  end

  def folders_limit
    current_plan.folders_limit
  end

  def folders_percentage
    return 0 if current_plan.unlimited_folders?

    [ (folders_count.to_f / folders_limit * 100).round(1), 100 ].min
  end

  def link_access_limit
    current_plan.link_access_limit
  end
end
