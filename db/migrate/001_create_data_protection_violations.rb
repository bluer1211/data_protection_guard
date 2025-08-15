# frozen_string_literal: true

class CreateDataProtectionViolations < ActiveRecord::Migration[6.0]
  def change
    create_table :data_protection_violations do |t|
      t.integer :user_id
      t.string :violation_type, null: false
      t.string :pattern, null: false
      t.text :match_content, null: false
      t.string :severity, default: 'medium'
      t.text :context
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    add_index :data_protection_violations, :user_id
    add_index :data_protection_violations, :violation_type
    add_index :data_protection_violations, :created_at
    add_index :data_protection_violations, [:user_id, :created_at]
  end
end
