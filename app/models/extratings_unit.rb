class ExtratingsUnit < ActiveRecord::Base
    has_many :extratings_list_units, foreign_key: :extratings_unit_id, dependent: :destroy
    has_many :extratings_lists, through: :extratings_list_units
  
    validates :name_ru, :name_eng, :measure_unit, presence: true
    validates :base_multiplier, numericality: true
  end
  