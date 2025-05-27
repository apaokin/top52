class CreateExtratingsLists < ActiveRecord::Migration
  def change
    create_table :extratings_lists do |t|
      t.string :name_ru
      t.string :name_eng
      t.text :description_ru
      t.text :description_eng
      t.string :url

      t.timestamps
    end
  end
end