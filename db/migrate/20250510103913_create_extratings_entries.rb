class CreateExtratingsEntries < ActiveRecord::Migration
  def change
    create_table :extratings_entries do |t|
      t.integer :system_id, null: false
      t.references :extratings_edition, null: false, foreign_key: { to_table: :extratings_editions }
      t.integer :position

      t.timestamps
    end

    add_foreign_key :extratings_entries, :top50_relations, column: :system_id, primary_key: :prim_obj_id, name: :fk_entries_top50_relations
  end
end