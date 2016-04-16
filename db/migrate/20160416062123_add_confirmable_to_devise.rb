class AddConfirmableToDevise < ActiveRecord::Migration
  def change
    execute("UPDATE users SET confirmed_at = NOW()")
  end
end
