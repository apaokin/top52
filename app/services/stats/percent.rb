module Stats
  module Percent
    module_function

    def of(part, total, precision = 2)
      denominator = total.to_f
      return 0.0 if denominator <= 0.0

      ((part.to_f * 100.0) / denominator).round(precision)
    end
  end
end
