module Stats
  class EditionTimeline
    def self.from_lists(top50_slists:, date_vals:)
      (top50_slists || []).each_with_object([]) do |top50_list, acc|
        date_val = date_vals.find_by(obj_id: top50_list.id)
        next unless date_val.present?

        parts = date_val.value.to_s.split(".")
        next unless parts.size >= 3

        acc << [parts[2], parts[1]]
      end
    end
  end
end
