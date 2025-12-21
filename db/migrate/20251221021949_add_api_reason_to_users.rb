class AddApiReasonToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :api_reason, :text
  end
end
