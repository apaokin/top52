class ExtratingsEntrySubmission
  include ActiveModel::Model

  attr_accessor :extratings_list_id, :edition_number, :publication_date,
                :position, :system_relation_id, :scores, :selected_units

  validate :validate_required_fields
  validate :validate_system_relation, on: :create
  validate :validate_scores_payload

  def machine_id
    system_relation&.prim_obj_id
  end

  def normalized_scores
    @normalized_scores ||= scores_hash.each_with_object([]) do |(key, score_value), result|
      next if score_value.blank?

      unit = selected_unit_for(key)
      next unless unit

      result << {
        key: key,
        score: score_value.to_f,
        extratings_list_unit_id: unit.id
      }
    end
  end

  private

  def validate_required_fields
    errors.add(:base, "Не выбран лист рейтинга") if extratings_list_id.blank?
    errors.add(:base, "Не указан номер редакции") if edition_number.blank?
    errors.add(:base, "Не указана дата публикации") if publication_date.blank?
    errors.add(:base, "Не указана позиция") if position.blank?
    errors.add(:base, "Не выбрана система") if validation_context == :create && system_relation_id.blank?
  end

  def validate_system_relation
    return if system_relation_id.blank?
    return if system_relation.present?

    errors.add(:base, "Выбрана некорректная система")
  end

  def validate_scores_payload
    if scores_hash.empty?
      errors.add(:base, "Не указаны показатели производительности")
      return
    end

    scores_hash.each do |key, score_value|
      errors.add(:base, "Не указано значение для показателя '#{key}'") if score_value.blank?

      unit_id = selected_units_hash[key]
      if unit_id.blank?
        errors.add(:base, "Не выбрана единица измерения для показателя '#{key}'")
        next
      end

      if selected_unit_for(key).nil?
        errors.add(:base, "Выбрана некорректная единица измерения для показателя '#{key}'")
      end
    end
  end

  def system_relation
    @system_relation ||= Top50Relation.find_by(id: system_relation_id)
  end

  def selected_unit_for(key)
    unit_id = selected_units_hash[key].to_i
    return nil if unit_id.zero?

    @selected_units_by_key ||= {}
    @selected_units_by_key[key] ||= ExtratingsListUnit.find_by(id: unit_id)
  end

  def scores_hash
    @scores_hash ||= normalize_hash(scores)
  end

  def selected_units_hash
    @selected_units_hash ||= normalize_hash(selected_units)
  end

  def normalize_hash(value)
    return {} if value.blank?
    return value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
    return value.to_h if value.respond_to?(:to_h)

    {}
  end
end
