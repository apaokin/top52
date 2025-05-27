class CreateExtratingsEntries < ActiveRecord::Migration
  def change
    create_table :extratings_entries do |t|
      t.integer :system_id, null: false
      t.references :extratings_edition, null: false, foreign_key: { to_table: :extratings_editions }
      t.integer :position

      t.timestamps
    end
  end  
end