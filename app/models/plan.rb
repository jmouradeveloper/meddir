class Plan < ApplicationRecord
  has_many :subscriptions, dependent: :restrict_with_error
  has_many :users, through: :subscriptions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def self.free
    find_by(slug: "free")
  end

  def self.premium
    find_by(slug: "premium")
  end

  def self.enterprise
    find_by(slug: "enterprise")
  end

  def unlimited_storage?
    storage_limit_mb.nil?
  end

  def unlimited_folders?
    folders_limit.nil?
  end

  def unlimited_links?
    active_links_limit.nil?
  end

  def unlimited_link_access?
    link_access_limit.nil?
  end

  def free?
    slug == "free"
  end
end
