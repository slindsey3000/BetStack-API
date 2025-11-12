class AddSyncTrackingToLeagues < ActiveRecord::Migration[8.0]
  def change
    add_column :leagues, :last_odds_sync_at, :datetime
    add_column :leagues, :last_results_sync_at, :datetime
    
    add_index :leagues, :last_odds_sync_at
    add_index :leagues, :last_results_sync_at
  end
end
