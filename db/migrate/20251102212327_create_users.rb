class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :api_key, null: false
      t.string :email, null: false
      t.string :phone_number, null: false
      t.text :address
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :users, :api_key, unique: true
    add_index :users, :email, unique: true
    add_index :users, :phone_number, unique: true
  end
end
