class CreateExtratingsScores < ActiveRecord::Migration
  def change
    create_table :extratings_scores do |t|
      t.references :extratings_entry, null: false, foreign_key: { to_table: :extratings_entries }
      t.references :extratings_list_unit, null: false, foreign_key: { to_table: :extratings_list_units }
      t.decimal :score
      t.decimal :normalized_score

      t.timestamps
    end
  end
end