SitemapGenerator::Sitemap.default_host = 'https://www.opensplittime.org'

SitemapGenerator::Sitemap.public_path = 'tmp/sitemaps/'

SitemapGenerator::Sitemap.create do

  add organizations_path
  add events_path
  add people_path
  add about_path
  add getting_started_path

  Organization.find_each do |organization|
    add organization_path(organization), lastmod: organization.updated_at
  end

  Event.find_each do |event|
    add event_path(event), lastmod: event.updated_at
  end

  Person.find_each do |person|
    add person_path(person), lastmod: person.updated_at
  end

  Effort.find_each do |effort|
    add person_path(effort), lastmod: effort.updated_at
  end
end
