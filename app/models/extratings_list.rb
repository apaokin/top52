class ExtratingsList < ActiveRecord::Base
  has_many :extratings_editions, class_name: 'ExtratingsEdition', foreign_key: 'extratings_list_id'
  has_many :extratings_list_units, foreign_key: :extratings_list_id
  accepts_nested_attributes_for :extratings_list_units
  has_many :extratings_units, through: :extratings_list_units

  validates :name_ru, presence: { message: "не может быть пустым" }
  validates :name_eng, presence: { message: "не может быть пустым" }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
end
