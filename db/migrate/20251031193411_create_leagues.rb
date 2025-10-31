class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |t|
      t.references :sport, null: false, foreign_key: true
      t.string :name
      t.string :key, null: false
      t.string :region
      t.boolean :active, default: true
      t.boolean :has_outrights, default: false

      t.timestamps
    end

    add_index :leagues, :key, unique: true
  end
end
