class AttributePuller

  def self.pull_attributes!(puller, target) # Morphs puller
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
    puller.save
  end

  private

  attr_reader :puller, :target

  def resolve_geo_conflicts
    puller.country_code ||= target.country_code unless country_conflict? || target_country_mismatch?
    unless state_conflict? || target_state_mismatch?
      puller.state_code ||= target.state_code
      puller.city ||= target.city
    end
  end

  def country_conflict?
    [puller.country_code, target.country_code].compact.uniq.count == 2
  end

  def state_conflict?
    [puller.state_code, target.state_code].compact.uniq.count == 2 || country_conflict?
  end

  def target_country_mismatch?
    puller.state_code &&
        Carmen::Country.coded(target.country_code).try(:subregions?) &&
        Carmen::Country.coded(target.country_code).subregions.exclude?(puller.state_code)
  end

  def target_state_mismatch?
    target.state_code &&
        Carmen::Country.coded(puller.country_code).try(:subregions?) &&
        Carmen::Country.coded(puller.country_code).subregions.exclude?(target.state_code)
  end

  def puller_attributes
    puller.class.columns_to_pull_from_model
  end
end