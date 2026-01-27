class ShareableLink < ApplicationRecord
  belongs_to :medical_folder

  before_create :generate_token
  before_create :set_defaults

  validates :token, uniqueness: true, allow_nil: true

  scope :active, -> { where(active: true).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  EXPIRATION_OPTIONS = {
    "1_day" => 1.day,
    "7_days" => 7.days,
    "30_days" => 30.days,
    "never" => nil
  }.freeze

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def access_limit_reached?
    access_limit.present? && access_count >= access_limit
  end

  def valid_for_access?
    active? && !expired? && !access_limit_reached?
  end

  def increment_access!
    increment!(:access_count)
  end

  def remaining_accesses
    return nil if access_limit.nil?

    [access_limit - access_count, 0].max
  end

  def formatted_expiration
    return I18n.t("expiration.never_expires") if expires_at.nil?

    if expired?
      I18n.t("expiration.expired_on", date: I18n.l(expires_at, format: :long))
    else
      I18n.t("expiration.expires_on", date: I18n.l(expires_at, format: :long))
    end
  end

  def formatted_access_limit
    return I18n.t("shareable_links.unlimited_access") if access_limit.nil?

    I18n.t("shareable_links.access_count_of_limit", count: access_count, limit: access_limit)
  end

  def days_until_expiration
    return nil if expires_at.nil?

    ((expires_at - Time.current) / 1.day).ceil
  end

  def user
    medical_folder.user
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_defaults
    self.active = true if active.nil?
    self.access_count ||= 0
    # Set access_limit based on user plan if not already set
    if access_limit.nil? && medical_folder.present?
      self.access_limit = user.link_access_limit
    end
  end
end
