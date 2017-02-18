class AttributePuller

  def self.pull_attributes!(puller, target) # Morphs puller, leaves target intact
    new(puller, target).pull_attributes!
  end

  def initialize(puller, target)
    @puller = puller
    @target = target
  end

  def pull_attributes!
    resolve_geo_conflicts
    puller_attributes.each do |attribute|
      puller.assign_attributes({attribute => target[attribute]}) if puller[attribute].blank?
    end
    if puller.save
      Rails.logger.info "#{puller.class} #{puller.name} updated"
      true
    else
      Rails.logger.info "#{puller.class} #{puller.name} could not be updated: #{puller.errors.full_messages}"
      false
    end
  end

  private

  attr_reader :puller, :target

  def resolve_geo_conflicts
    puller.country_code ||= target.country_code unless country_conflict? || target_country_mismatch?
    puller.state_code ||= target.state_code unless state_conflict? || target_state_mismatch?
    puller.city ||= target.city unless state_conflict? || target_state_mismatch?
  end

  def country_conflict?
    [puller.country_code, target.country_code].compact.uniq.count == 2
  end

  def state_conflict?
    [puller.state_code, target.state_code].compact.uniq.count == 2 || country_conflict?
  end

  def target_country_mismatch?
    puller.state_code &&
        target_country.try(:subregions?) &&
        target_subregion_codes.exclude?(puller.state_code)
  end

  def target_state_mismatch?
    target.state_code &&
        puller_country.try(:subregions?) &&
        puller_subregion_codes.exclude?(target.state_code)
  end

  def puller_country
    Carmen::Country.coded(puller.country_code)
  end

  def target_country
    Carmen::Country.coded(target.country_code)
  end

  def puller_subregion_codes
    puller_country.subregions.map(&:code)
  end

  def target_subregion_codes
    target_country.subregions.map(&:code)
  end

  def puller_attributes
    puller.class.columns_to_pull_from_model
  end
end