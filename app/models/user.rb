class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :medical_folders, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, length: { maximum: 100 }

  def display_name
    name.presence || email_address.split("@").first.titleize
  end
end
