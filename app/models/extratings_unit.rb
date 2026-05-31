class ExtratingsUnit < ActiveRecord::Base
    has_many :extratings_list_units, foreign_key: :extratings_unit_id, dependent: :destroy
    has_many :extratings_lists, through: :extratings_list_units
  
    validates :name_ru, presence: { message: "не может быть пустым" }
    validates :name_eng, presence: { message: "не может быть пустым" }
    validates :measure_unit, presence: { message: "не может быть пустым" }
    validates :base_multiplier, numericality: {
      greater_than: 0,
      message: "должен быть больше 0"
    }
  end
  