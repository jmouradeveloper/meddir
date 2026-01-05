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

  def valid_for_access?
    active? && !expired?
  end

  def formatted_expiration
    return "Never expires" if expires_at.nil?

    if expired?
      "Expired on #{expires_at.strftime('%B %d, %Y')}"
    else
      "Expires on #{expires_at.strftime('%B %d, %Y at %I:%M %p')}"
    end
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
  end
end
