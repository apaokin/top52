class ChangeScoreTypesInExtratingsScores < ActiveRecord::Migration
  def change
    change_column :extratings_scores, :score, :decimal, precision: 100, scale: 40
    change_column :extratings_scores, :normalized_score, :decimal, precision: 100, scale: 40
  end
end
