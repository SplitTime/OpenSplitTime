class MakeSubscriptionsPolymorphic < ActiveRecord::Migration[5.2]
  def up
    add_reference :subscriptions, :subscribable, polymorphic: true

    query = "update subscriptions set subscribable_type = 'Person', subscribable_id = person_id"
    ActiveRecord::Base.connection.execute(query)

    remove_reference :subscriptions, :person
    add_index :subscriptions, [:user_id, :subscribable_type, :subscribable_id, :protocol],
              name: 'index_subscriptions_on_unique_fields', unique: true
  end

  def down
    add_reference :subscriptions, :person

    query = "update subscriptions set person_id = subscribable_id where subscribable_type = 'Person';"
    ActiveRecord::Base.connection.execute(query)
    Subscription.where(person_id: nil).each(&:destroy)

    add_index :subscriptions, [:user_id, :person_id, :protocol], unique: true

    remove_reference :subscriptions, :subscribable, polymorphic: true
  end
end
