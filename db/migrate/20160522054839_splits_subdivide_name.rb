class SplitsSubdivideName < ActiveRecord::Migration
  def self.up
    add_column :splits, :base_name, :string
    add_column :splits, :name_extension, :string
    Split.all.each do |split|
      base_name = split.name.split.reject { |x| (x.downcase == 'in') | (x.downcase == 'out') }.join(' ')
      name_extension = split.name.gsub(base_name, '').strip
      name_extension = name_extension.present? ? name_extension : nil
      split.update(base_name: base_name, name_extension: name_extension)
    end
    remove_column :splits, :name
  end

  def self.down
    add_column :splits, :name, :string
    Split.all.each do |split|
      split.update(name: [split.base_name, split.name_extension]
                             .map { |x| x.present? ? x : nil }
                             .compact
                             .join(' '))
    end
    remove_column :splits, :base_name
    remove_column :splits, :name_extension
  end
end
