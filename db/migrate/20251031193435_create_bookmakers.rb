class CreateBookmakers < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmakers do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.string :region
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :bookmakers, :key, unique: true
  end
end
