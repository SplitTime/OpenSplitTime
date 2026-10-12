class CreateMastersAndGrandmastersWithNonbinaryTemplate < ActiveRecord::Migration[8.1]
  # The fixtures have defined this template since 2023, but it was never
  # created in production. Built from the existing Masters and Grandmasters
  # categories with Overall Nonbinary inserted after the overall podiums.
  def up
    return if ResultsTemplate.exists?(slug: "masters-and-grandmasters-with-nonbinary")

    base_template = ResultsTemplate.find_by!(slug: "masters-and-grandmasters")
    nonbinary_overall = ResultsCategory.find_by!(slug: "nonbinary-overall", organization_id: nil)
    categories = base_template.template_categories.map(&:category).insert(2, nonbinary_overall)

    ResultsTemplate.transaction do
      template = ResultsTemplate.create!(
        name: "Masters and Grandmasters with Nonbinary",
        aggregation_method: base_template.aggregation_method,
        podium_size: base_template.podium_size,
      )
      categories.each.with_index(1) do |category, position|
        template.template_categories.create!(category: category, position: position)
      end
    end

    say "Created Masters and Grandmasters with Nonbinary with #{categories.size} categories"
  end

  def down
    ResultsTemplate.find_by(slug: "masters-and-grandmasters-with-nonbinary")&.destroy!
  end
end
