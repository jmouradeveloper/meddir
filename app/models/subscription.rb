class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan

  BILLING_CYCLES = %w[monthly annual].freeze
  STATUSES = %w[active cancelled expired].freeze

  validates :billing_cycle, inclusion: { in: BILLING_CYCLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: true

  scope :active, -> { where(status: "active") }
  scope :expired, -> { where(status: "expired") }

  before_create :set_start_date

  def active?
    status == "active" && (ends_at.nil? || ends_at > Time.current)
  end

  def expired?
    status == "expired" || (ends_at.present? && ends_at <= Time.current)
  end

  def days_remaining
    return nil if ends_at.nil?
    return 0 if ends_at <= Time.current

    ((ends_at - Time.current) / 1.day).ceil
  end

  def renew!(cycle: billing_cycle)
    duration = cycle == "annual" ? 1.year : 1.month
    update!(
      billing_cycle: cycle,
      status: "active",
      starts_at: Time.current,
      ends_at: Time.current + duration
    )
  end

  def cancel!
    update!(status: "cancelled")
  end

  private

  def set_start_date
    self.starts_at ||= Time.current
  end
end
