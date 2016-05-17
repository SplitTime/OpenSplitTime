Dir[File.join(Rails.root, 'lib', '*.rb')].each do |f|
  require f
end