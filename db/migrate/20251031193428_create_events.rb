class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :league, null: false, foreign_key: true
      t.bigint :home_team_id, null: false
      t.bigint :away_team_id, null: false
      t.string :odds_api_id, null: false
      t.string :home_team_name
      t.string :away_team_name
      t.datetime :commence_time
      t.string :status
      t.boolean :completed, default: false
      t.boolean :preseason, default: false
      t.datetime :last_sync_at

      t.timestamps
    end

    add_index :events, :odds_api_id, unique: true
    add_index :events, :commence_time
    add_index :events, :home_team_id
    add_index :events, :away_team_id
    add_foreign_key :events, :teams, column: :home_team_id
    add_foreign_key :events, :teams, column: :away_team_id
  end
end
