class CreateResults < ActiveRecord::Migration[8.0]
  def change
    create_table :results do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :home_score
      t.integer :away_score
      t.boolean :final, default: false

      t.timestamps
    end

    add_index :results, :event_id, unique: true
  end
end
