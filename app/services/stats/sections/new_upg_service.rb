module Stats
  module Sections
    class NewUpgService
      def initialize(context:)
        @context = context
      end

      def call
        context.instance_eval do
          @all_ratings_data = []
          top50_slists = get_top50_lists_sorted
          top_50_dates = []

          top50_slists.each do |top50_list|
            date_val = @date_vals.find_by(obj_id: top50_list.id)
            next unless date_val.present?

            list_year = date_val.value.split(".")[2]
            list_month = date_val.value.split(".")[1]
            top_50_dates.push([list_year, list_month])
          end

          top_50_dates.each do |top50_date|
            list_id = get_list_id_by_date(top50_date[0], top50_date[1])
            top50_machines = fetch_archive_list(list_id)
            rating_data = {
              list_id: list_id,
              date: top50_date,
              machines: top50_machines,
              num_vals: @num_vals.dup,
              date_vals: @date_vals.dup,
              prec_machines: @prec_machines.dup,
              ed_num_attrid: @ed_num_attrid.dup,
              ed_date_attrid: @ed_date_attrid.dup,
              prev_rated_pos: @prev_rated_pos.dup
            }
            @all_ratings_data << rating_data
          end
          @ratings_summary = []

          rmax_by_machine = Top50BenchmarkResult.where(benchmark_id: @rmax_benchid).index_by(&:machine_id)
          rpeak_rows = ActiveRecord::Base.connection.select_all(
            "SELECT obj_id, cast(encode(value, 'escape') as double precision) as num FROM top50_attribute_val_dbvals WHERE attr_id = #{@rpeak_attrid}"
          )
          rpeak_by_machine = rpeak_rows.rows.each_with_object({}) do |row, h|
            val = (row[1] || 0).to_f
            h[row[0].to_i] = val
            h[row[0].to_s] = val
          end

          @all_ratings_data.pop
          @all_ratings_data.each do |rating|
            new_mach = 0
            upg_mach = 0
            sum_rmax_new = 0.0
            sum_rmax_upg = 0.0
            sum_rpeak_new = 0.0
            sum_rpeak_upg = 0.0
            sum_rmax_total = 0.0
            sum_rpeak_total = 0.0

            rating[:machines].each do |top50_machine|
              prev_rank_pos = rating[:prev_rated_pos].find { |pos| pos.machine_id == top50_machine["id"] }
              is_upg = false
              prec_machine = nil

              if prev_rank_pos.nil?
                prec_machine = rating[:prec_machines].find { |prec| prec["sec_obj_id"] == top50_machine["id"] }
                if prec_machine.present?
                  prev_rank_pos = rating[:prev_rated_pos].find { |pos| pos.machine_id == prec_machine["prim_obj_id"] }
                  is_upg = true if prev_rank_pos.present?
                end
              end

              if prev_rank_pos.present?
                upg_mach += 1 if is_upg
              elsif prec_machine.present?
                upg_mach += 1
              else
                new_mach += 1
              end

              mid = top50_machine["id"]
              rmax_rec = rmax_by_machine[mid] || (mid.respond_to?(:to_i) ? rmax_by_machine[mid.to_i] : nil)
              rmax_val = (rmax_rec&.result || 0).to_f
              rpeak_val = rpeak_by_machine[mid] || (mid.respond_to?(:to_i) ? rpeak_by_machine[mid.to_i] : nil) || 0.0
              sum_rmax_total += rmax_val
              sum_rpeak_total += rpeak_val
              if prev_rank_pos.present?
                if is_upg
                  sum_rmax_upg += rmax_val
                  sum_rpeak_upg += rpeak_val
                end
              elsif prec_machine.present?
                sum_rmax_upg += rmax_val
                sum_rpeak_upg += rpeak_val
              else
                sum_rmax_new += rmax_val
                sum_rpeak_new += rpeak_val
              end
            end

            @ratings_summary << {
              list_id: rating[:list_id],
              num_vals: rating[:num_vals],
              date_vals: rating[:date_vals],
              date: rating[:date].join("-"),
              new_machines: new_mach,
              upgraded_machines: upg_mach,
              total_machines: new_mach + upg_mach,
              sum_rmax_new: sum_rmax_new,
              sum_rmax_upg: sum_rmax_upg,
              sum_rmax_total: sum_rmax_total,
              sum_rpeak_new: sum_rpeak_new,
              sum_rpeak_upg: sum_rpeak_upg,
              sum_rpeak_total: sum_rpeak_total
            }
          end

          new_upg_payload = Stats::NewUpgBuilder.new(
            ratings_summary: @ratings_summary,
            all_ratings_data: @all_ratings_data,
            num_vals: @num_vals,
            date_vals: @date_vals
          ).call
          @ratings_chart_data = new_upg_payload[:ratings_chart_data]
          @ratings_rpeak_pct_chart_data = new_upg_payload[:ratings_rpeak_pct_chart_data]
          @ratings_rmax_pct_chart_data = new_upg_payload[:ratings_rmax_pct_chart_data]
          @edition_dates_new_upg = new_upg_payload[:edition_dates_new_upg]
          @ratings_summary_for_js = new_upg_payload[:ratings_summary_for_js]
          @ratings_table_rows = new_upg_payload[:ratings_table_rows]
          @csv_string_new_upg = new_upg_payload[:csv_string_new_upg]
        end
      end

      private

      attr_reader :context
    end
  end
end
