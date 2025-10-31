class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.references :league, null: false, foreign_key: true
      t.string :name, null: false
      t.string :normalized_name
      t.string :abbreviation
      t.string :city
      t.string :conference
      t.string :division
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :teams, [:league_id, :normalized_name], unique: true
  end
end
