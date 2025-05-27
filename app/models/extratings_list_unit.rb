class ExtratingsListUnit < ActiveRecord::Base
    belongs_to :extratings_list, class_name: 'ExtratingsList', foreign_key: :extratings_list_id
    belongs_to :extratings_unit, class_name: 'ExtratingsUnit', foreign_key: :extratings_unit_id
  
    has_many :extratings_scores, foreign_key: :extratings_list_unit_id, dependent: :destroy
  
    validates :extratings_list, :extratings_unit, presence: true
    validates :priority, numericality: { only_integer: true }, allow_nil: true
end
  