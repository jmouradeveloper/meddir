# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Plans
puts "Creating plans..."

Plan.find_or_create_by!(slug: "free") do |p|
  p.name = "Gratuito"
  p.storage_limit_mb = 100
  p.folders_limit = 3
  p.sharing_enabled = false
  p.active_links_limit = 0
  p.link_access_limit = 0
  p.monthly_price = 0
  p.annual_price = 0
  p.active = true
end

Plan.find_or_create_by!(slug: "premium") do |p|
  p.name = "Premium"
  p.storage_limit_mb = 5120  # 5 GB
  p.folders_limit = 20
  p.sharing_enabled = true
  p.active_links_limit = 10
  p.link_access_limit = 100
  p.monthly_price = 19.90
  p.annual_price = 199.00
  p.active = true
end

Plan.find_or_create_by!(slug: "enterprise") do |p|
  p.name = "Enterprise"
  p.storage_limit_mb = nil  # unlimited
  p.folders_limit = nil     # unlimited
  p.sharing_enabled = true
  p.active_links_limit = nil  # unlimited
  p.link_access_limit = nil   # unlimited
  p.monthly_price = 49.90
  p.annual_price = 499.00
  p.active = true
end

puts "Plans created: #{Plan.count}"
