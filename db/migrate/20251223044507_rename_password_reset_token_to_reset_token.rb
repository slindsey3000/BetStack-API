class RenamePasswordResetTokenToResetToken < ActiveRecord::Migration[8.0]
  def change
    # Rename columns to avoid conflict with Rails 7.1+ has_secure_password
    # which automatically adds password_reset_token method
    rename_column :users, :password_reset_token, :reset_token
    rename_column :users, :password_reset_sent_at, :reset_token_sent_at
  end
end
