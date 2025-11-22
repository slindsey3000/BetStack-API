class CreateApiUsageLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :api_usage_logs do |t|
      t.date :date, null: false
      t.string :league_key, null: false
      t.integer :request_count, default: 0, null: false

      t.timestamps
    end

    # Unique index to prevent duplicate entries for same date/league
    add_index :api_usage_logs, [:date, :league_key], unique: true
    
    # Index for efficient date queries
    add_index :api_usage_logs, :date
  end
end
