module Stats
  module Sections
    class ListUpgService < BaseSectionService

      def call
        run_in_context do
          precedes_map = precedes_child_to_parent_map_for_lineage
          @ed_num_attrid = Top50Attribute.find_by(name_eng: "Edition number")&.id
          @ed_date_attrid = Top50Attribute.find_by(name_eng: "Edition date")&.id

          @new_upd_data = []
          top50_slists = get_top50_lists_sorted
          top_50_dates = Stats::EditionTimeline.from_lists(top50_slists: top50_slists, date_vals: @date_vals)
          max_rank_limit = @max_rank || self.class::TOP50_MAX_RANK
          list_entries = top_50_dates.each_with_index.map do |top50_date, idx|
            { list_id: get_list_id_by_date(top50_date[0], top50_date[1]), date: top50_date, idx: idx }
          end.select { |entry| entry[:list_id].present? }
          list_ids = list_entries.map { |entry| entry[:list_id] }
          machine_ids_by_list = list_entries.each_with_object({}) do |entry, h|
            h[entry[:list_id]] = ranked_machine_ids_for_list(entry[:list_id], max_rank_limit)
          end
          all_machine_ids = machine_ids_by_list.values.flatten.uniq
          machine_names_by_id = machine_display_name_map_for_ids(all_machine_ids)
          list_num_by_id = @num_vals.where(obj_id: list_ids).pluck(:obj_id, :value).to_h

          prev_list_ids = top50_slists.each_with_index.map { |_list, idx| top50_slists[idx + 1]&.id }.compact.uniq
          prev_results_by_list = Top50BenchmarkResult.where(benchmark_id: prev_list_ids).group_by(&:benchmark_id)
          prev_rank_by_list = prev_results_by_list.each_with_object({}) do |(benchmark_id, rows), h|
            h[benchmark_id] = rows.each_with_object({}) do |pos, map|
              map[pos.machine_id] ||= pos
            end
          end

          list_entries.each_with_index do |entry, idx|
            list_id = entry[:list_id]
            top50_date = entry[:date]
            is_first_list = (idx == list_entries.size - 1)
            prev_list_id = top50_slists[entry[:idx] + 1]&.id
            prev_rated_pos_by_machine_id = prev_list_id.present? ? (prev_rank_by_list[prev_list_id] || {}) : {}
            (machine_ids_by_list[list_id] || []).each_with_index do |machine_id, rank_index|
              new_upd_status = nil
              pos_status = nil
              rank_change = nil
              rank_pos = rank_index + 1
              unless is_first_list
                is_upg = false
                prev_mid = nil
                prev_rank_pos = prev_rated_pos_by_machine_id[machine_id]

                if prev_rank_pos.nil?
                  prev_mid = precedes_map[machine_id]
                  if prev_mid.present?
                    prev_rank_pos = prev_rated_pos_by_machine_id[prev_mid]
                    is_upg = true if prev_rank_pos.present?
                  end
                end
                if prev_rank_pos.present?
                  prev_rank = prev_rank_pos.result.to_i
                  if rank_pos != prev_rank
                    rank_change = prev_rank - rank_pos
                    pos_status = rank_change > 0 ? "moved_up" : "moved_down"
                  end
                  new_upd_status = "updated" if is_upg
                else
                  new_upd_status = prev_mid.present? ? "updated" : "new"
                end
              end

              list_num = list_num_by_id[list_id]
              machine_name = machine_names_by_id[machine_id] || "н/д"
              machine_key = Stats::Lineage.branch_key_machine_id(machine_id, precedes_map)
              @new_upd_data << {
                edition: top50_date.join("-"),
                list_id: list_id,
                list_num: list_num,
                rank: rank_pos,
                new_upd_status: new_upd_status,
                pos_status: pos_status,
                rank_change: rank_change,
                machine_id: machine_id,
                machine_name: machine_name,
                machine_key: machine_key
              }
            end
          end
          merge_application_area_into_heatmap_rows!(@new_upd_data)
          list_upg_payload = Stats::ListUpgBuilder.new(
            new_upd_data: @new_upd_data,
            top50_slists: top50_slists,
            num_vals: @num_vals,
            max_rank: (@max_rank || self.class::TOP50_MAX_RANK)
          ).call
          @new_upd_data = list_upg_payload[:new_upd_data]
          @new_upd_data_2d = list_upg_payload[:new_upd_data_2d]
          @new_upd_list_ids = list_upg_payload[:new_upd_list_ids]
          @new_upd_list_nums = list_upg_payload[:new_upd_list_nums]
          @new_upd_matrix = list_upg_payload[:new_upd_matrix]
          @csv_string_list_upg = list_upg_payload[:csv_string_list_upg]
          @chart_data = list_upg_payload[:chart_data_json]
        end
      end

      private
    end
  end
end
