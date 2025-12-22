class CreateClientApiUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :client_api_usages do |t|
      t.date :date, null: false
      t.integer :hour, null: false  # 0-23
      t.string :api_key, null: false
      t.string :email, null: false
      t.integer :request_count, default: 0, null: false
      t.integer :rejected_count, default: 0, null: false

      t.timestamps
    end

    # Unique index for upsert operations
    add_index :client_api_usages, [:date, :hour, :api_key], unique: true, name: 'idx_client_usage_unique'
    
    # Query indexes
    add_index :client_api_usages, :email
    add_index :client_api_usages, :date
    add_index :client_api_usages, :api_key
  end
end
