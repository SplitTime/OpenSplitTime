# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Environment variables (ENV['...']) can be set in the file .env file.

User.create!(name: 'Admin User', role: :admin, email: 'user@example.com', password: 'password', encrypted_password: '$2a$10$0j0An.uGnBswcVIJBEGuHOtCZ1qk3RZpZ3rFfoa7VKpRc7pjSgz2e')