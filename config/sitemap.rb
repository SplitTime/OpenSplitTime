SitemapGenerator::Sitemap.default_host = 'https://www.opensplittime.org'

SitemapGenerator::Sitemap.public_path = 'tmp/sitemaps/'

SitemapGenerator::Sitemap.create do

  add organizations_path
  add event_groups_path
  add people_path
  add about_path
  add donations_path
  add docs_contents_path

  Organization.visible.find_each do |organization|
    add organization_path(organization), lastmod: organization.updated_at
  end

  EventGroup.visible.find_each do |event_group|
    add event_group_path(event_group), lastmod: event_group.updated_at
  end

  Event.visible.find_each do |event|
    add event_path(event), lastmod: event.updated_at
  end

  Person.visible.find_each do |person|
    add person_path(person), lastmod: person.updated_at
  end

  Effort.visible.find_each do |effort|
    add person_path(effort), lastmod: effort.updated_at
  end
end
