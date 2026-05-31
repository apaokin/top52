class CreateExtratingsEditions < ActiveRecord::Migration
  def change
    create_table :extratings_editions do |t|
      t.references :extratings_list, null: false, foreign_key: true
      t.integer :edition_number
      t.date :publication_date
      t.integer :edition_multiplier

      t.timestamps
    end
  end
end