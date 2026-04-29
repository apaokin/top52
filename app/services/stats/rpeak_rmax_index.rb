module Stats
  class RpeakRmaxIndex
    def self.build(rpeak_attrid:, rmax_benchid:)
      rmax_by_machine = Top50BenchmarkResult.where(benchmark_id: rmax_benchid).index_by(&:machine_id)
      sql = ActiveRecord::Base.send(
        :sanitize_sql_array,
        [
          "SELECT obj_id, cast(encode(value, 'escape') as double precision) as num FROM top50_attribute_val_dbvals WHERE attr_id = ?",
          rpeak_attrid
        ]
      )
      rpeak_rows = ActiveRecord::Base.connection.select_all(sql)
      rpeak_by_machine = rpeak_rows.rows.each_with_object({}) do |row, h|
        val = (row[1] || 0).to_f
        h[row[0].to_i] = val
        h[row[0].to_s] = val
      end

      { rpeak_by_machine: rpeak_by_machine, rmax_by_machine: rmax_by_machine }
    end
  end
end
