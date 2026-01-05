class MedicalFolder < ApplicationRecord
  belongs_to :user
  has_many :documents, dependent: :destroy
  has_many :shareable_links, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :specialty, presence: true, inclusion: { in: ->(_) { SPECIALTIES.keys.map(&:to_s) } }

  scope :by_specialty, ->(specialty) { where(specialty: specialty) }
  scope :recent, -> { order(created_at: :desc) }

  SPECIALTIES = {
    general: { name: "General Practice", icon: "heart", color: "emerald" },
    cardiology: { name: "Cardiology", icon: "heart", color: "red" },
    dermatology: { name: "Dermatology", icon: "sun", color: "amber" },
    endocrinology: { name: "Endocrinology", icon: "beaker", color: "purple" },
    gastroenterology: { name: "Gastroenterology", icon: "clipboard", color: "orange" },
    neurology: { name: "Neurology", icon: "lightning", color: "indigo" },
    oncology: { name: "Oncology", icon: "shield", color: "pink" },
    ophthalmology: { name: "Ophthalmology", icon: "eye", color: "cyan" },
    orthopedics: { name: "Orthopedics", icon: "user", color: "lime" },
    pediatrics: { name: "Pediatrics", icon: "star", color: "yellow" },
    psychiatry: { name: "Psychiatry", icon: "chat", color: "violet" },
    pulmonology: { name: "Pulmonology", icon: "cloud", color: "sky" },
    radiology: { name: "Radiology", icon: "photo", color: "slate" },
    urology: { name: "Urology", icon: "beaker", color: "teal" },
    gynecology: { name: "Gynecology", icon: "heart", color: "rose" },
    other: { name: "Other", icon: "folder", color: "gray" }
  }.freeze

  def specialty_info
    SPECIALTIES[specialty.to_sym] || SPECIALTIES[:other]
  end

  def specialty_name
    specialty_info[:name]
  end

  def specialty_color
    specialty_info[:color]
  end

  def documents_count
    documents.count
  end
end
