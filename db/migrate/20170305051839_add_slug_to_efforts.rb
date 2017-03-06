class AddSlugToEfforts < ActiveRecord::Migration
  def self.up
    add_column :efforts, :slug, :string
    add_index :efforts, :slug, unique: true

    say 'Adding slugs to efforts'
    Effort.find_each do |effort|
      $stdout.sync = true
      if effort.save
        puts "Generating slug for #{effort.full_name}"
      else
        puts "Failed to generate slug for #{effort.full_name}"
      end
    end

    change_column_null :efforts, :slug, false
  end

  def self.down
    change_column_null :efforts, :slug, true
    remove_index :efforts, :slug
    remove_column :efforts, :slug
  end
end
