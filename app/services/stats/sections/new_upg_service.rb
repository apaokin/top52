module Stats
  module Sections
    class NewUpgService < BaseSectionService

      def call
        ensure_machine_attrs!
        run_in_context do
          @all_ratings_data = []
          top50_slists = get_top50_lists_sorted
          top_50_dates = Stats::EditionTimeline.from_lists(top50_slists: top50_slists, date_vals: @date_vals)
          max_rank_limit = @max_rank || self.class::TOP50_MAX_RANK
          precedes_by_child = precedes_child_to_parent_map_for_lineage

          list_entries = top_50_dates.each_with_index.map do |top50_date, idx|
            { list_id: get_list_id_by_date(top50_date[0], top50_date[1]), date: top50_date, idx: idx }
          end.select { |entry| entry[:list_id].present? }
          ranked_machine_ids_by_list = list_entries.each_with_object({}) do |entry, h|
            h[entry[:list_id]] = ranked_machine_ids_for_list(entry[:list_id], max_rank_limit)
          end
          prev_list_id_by_list_id = list_entries.each_with_object({}) do |entry, h|
            h[entry[:list_id]] = top50_slists[entry[:idx] + 1]&.id
          end
          prev_list_ids = prev_list_id_by_list_id.values.compact.uniq
          prev_results_by_list = Top50BenchmarkResult.where(benchmark_id: prev_list_ids).group_by(&:benchmark_id)
          prev_rank_by_list = prev_results_by_list.each_with_object({}) do |(benchmark_id, rows), h|
            h[benchmark_id] = rows.each_with_object({}) do |pos, map|
              map[pos.machine_id] ||= pos
            end
          end
          prev_rank_by_list_id = list_entries.each_with_object({}) do |entry, h|
            prev_list_id = prev_list_id_by_list_id[entry[:list_id]]
            h[entry[:list_id]] = prev_list_id.present? ? (prev_rank_by_list[prev_list_id] || {}) : {}
          end

          list_entries.each do |entry|
            list_id = entry[:list_id]
            rating_data = {
              list_id: list_id,
              date: entry[:date],
              machines: ranked_machine_ids_by_list[list_id] || [],
              prev_rank_by_machine: prev_rank_by_list_id[list_id] || {},
              precedes_by_child: precedes_by_child
            }
            @all_ratings_data << rating_data
          end
          @ratings_summary = []

          indexes = Stats::RpeakRmaxIndex.build(rpeak_attrid: @rpeak_attrid, rmax_benchid: @rmax_benchid)
          rmax_by_machine = indexes[:rmax_by_machine]
          rpeak_by_machine = indexes[:rpeak_by_machine]
          lookup_machine_value = lambda do |map, machine_id|
            map[machine_id] || map[machine_id.to_i] || map[machine_id.to_s]
          end

          @all_ratings_data.each_with_index do |rating, idx|
            next if idx == @all_ratings_data.size - 1

            new_mach = 0
            upg_mach = 0
            sum_rmax_new = 0.0
            sum_rmax_upg = 0.0
            sum_rpeak_new = 0.0
            sum_rpeak_upg = 0.0
            sum_rmax_total = 0.0
            sum_rpeak_total = 0.0

            rating[:machines].each do |machine_id|
              prev_rank_pos = rating[:prev_rank_by_machine][machine_id]
              is_upg = false
              prev_mid = nil

              if prev_rank_pos.nil?
                prev_mid = rating[:precedes_by_child][machine_id]
                if prev_mid.present?
                  prev_rank_pos = rating[:prev_rank_by_machine][prev_mid]
                  is_upg = true if prev_rank_pos.present?
                end
              end

              if prev_rank_pos.present?
                upg_mach += 1 if is_upg
              elsif prev_mid.present?
                upg_mach += 1
              else
                new_mach += 1
              end

              mid = machine_id
              rmax_rec = lookup_machine_value.call(rmax_by_machine, mid)
              rmax_val = (rmax_rec&.result || 0).to_f
              rpeak_val = lookup_machine_value.call(rpeak_by_machine, mid) || 0.0
              sum_rmax_total += rmax_val
              sum_rpeak_total += rpeak_val
              if prev_rank_pos.present?
                if is_upg
                  sum_rmax_upg += rmax_val
                  sum_rpeak_upg += rpeak_val
                end
              elsif prev_mid.present?
                sum_rmax_upg += rmax_val
                sum_rpeak_upg += rpeak_val
              else
                sum_rmax_new += rmax_val
                sum_rpeak_new += rpeak_val
              end
            end

            @ratings_summary << {
              list_id: rating[:list_id],
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
    end
  end
end
