module Stats
  class EditionLabel
    def self.from_list_date(list_date)
      return nil if list_date.blank?

      parts = list_date.to_s.split(".")
      return list_date if parts.size < 3

      "#{parts[1]}.#{parts[2][-2..-1]}"
    end

    def self.from_month_year(month:, year:)
      "#{month}.#{year.to_s[-2..-1]}"
    end
  end
end
