class ExtratingsListUnit < ActiveRecord::Base
    belongs_to :extratings_list, class_name: 'ExtratingsList', foreign_key: :extratings_list_id
    belongs_to :extratings_unit, class_name: 'ExtratingsUnit', foreign_key: :extratings_unit_id
  
    has_many :extratings_scores, foreign_key: :extratings_list_unit_id, dependent: :destroy
  
    accepts_nested_attributes_for :extratings_unit

    validates :extratings_list_id, presence: true, on: :update
    validates :priority, numericality: { only_integer: true }, allow_nil: true

    validate :extratings_unit_or_nested_attributes_present

    private

    def extratings_unit_or_nested_attributes_present
      return if extratings_unit_id.present?
      return if extratings_unit.present?

      errors.add(:base, "Для каждой единицы измерения необходимо выбрать существующую или создать новую")
    end
end
  