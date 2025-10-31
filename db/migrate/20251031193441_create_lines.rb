class CreateLines < ActiveRecord::Migration[8.0]
  def change
    create_table :lines do |t|
      t.references :event, null: false, foreign_key: true
      t.references :bookmaker, null: false, foreign_key: true
      t.string :source, default: "the-odds-api"
      t.string :odd_type
      
      # Moneyline (h2h market)
      t.decimal :money_line_home, precision: 10, scale: 2
      t.decimal :money_line_away, precision: 10, scale: 2
      t.decimal :draw_line, precision: 10, scale: 2
      
      # Point Spread (spreads market)
      t.decimal :point_spread_home, precision: 8, scale: 2
      t.decimal :point_spread_away, precision: 8, scale: 2
      t.decimal :point_spread_home_line, precision: 10, scale: 2
      t.decimal :point_spread_away_line, precision: 10, scale: 2
      
      # Totals (totals market)
      t.decimal :total_number, precision: 8, scale: 2
      t.decimal :over_line, precision: 10, scale: 2
      t.decimal :under_line, precision: 10, scale: 2
      
      t.datetime :last_updated
      t.jsonb :participant_data

      t.timestamps
    end

    add_index :lines, [:event_id, :bookmaker_id], unique: true
  end
end
