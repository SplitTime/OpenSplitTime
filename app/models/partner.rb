class Partner < ActiveRecord::Base
  belongs_to :event
  strip_attributes collapse_spaces: true

  has_attached_file :banner,
                    styles: {medium: '728x90>', small: '364x45>'},
                    default_url: '/images/:style/missing_banner.png'

  validates_attachment :banner,
                       content_type: { content_type: %w(image/png image/jpeg)},
                       file_name: { matches: [/png\z/, /jpe?g\z/] },
                       size: { in: 0..500.kilobytes }

  validates_presence_of :name
end
