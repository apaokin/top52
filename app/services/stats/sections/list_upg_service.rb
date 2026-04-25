module Stats
  module Sections
    class ListUpgService < BaseSectionService

      def call
        run_in_context do
          precedes_map = Stats::Lineage.precedes_child_to_parent_map
          @ed_num_attrid = Top50Attribute.where(name_eng: "Edition number").first&.id
          @ed_date_attrid = Top50Attribute.where(name_eng: "Edition date").first&.id

          @new_upd_data = []
          top50_slists = get_top50_lists_sorted
          top_50_dates = Stats::EditionTimeline.from_lists(top50_slists: top50_slists, date_vals: @date_vals)

          all_ratings_list_upg = []
          top_50_dates.each_with_index do |top50_date, idx|
            list_id = get_list_id_by_date(top50_date[0], top50_date[1])
            top50_machines = fetch_archive_list(list_id)
            prev_rated_pos_by_machine_id = {}
            if idx + 1 < top50_slists.size
              prev_list_id = top50_slists[idx + 1].id
              prev_rated_pos_by_machine_id = Top50BenchmarkResult.where(benchmark_id: prev_list_id).each_with_object({}) do |pos, h|
                h[pos.machine_id] ||= pos
              end
            end
            rating_data = {
              list_id: list_id,
              date: top50_date,
              machines: top50_machines,
              precedes_map: precedes_map,
              prev_rated_pos_by_machine_id: prev_rated_pos_by_machine_id
            }
            all_ratings_list_upg << rating_data
          end

          all_ratings_list_upg.each_with_index do |rating_data, idx|
            top50_date = rating_data[:date]
            is_first_list = (idx == all_ratings_list_upg.size - 1)
            rating_data[:machines].each do |top50_machine|
              machine_id = top50_machine["id"]
              new_upd_status = nil
              pos_status = nil
              rank_change = nil
              rank_pos = top50_machine["result"].to_i
              unless is_first_list
                is_upg = false
                prev_mid = nil
                prev_rank_pos = rating_data[:prev_rated_pos_by_machine_id][machine_id]

                if prev_rank_pos.nil?
                  prev_mid = rating_data[:precedes_map][machine_id]
                  if prev_mid.present?
                    prev_rank_pos = rating_data[:prev_rated_pos_by_machine_id][prev_mid]
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

              list_num = @num_vals.find_by(obj_id: rating_data[:list_id])&.value
              machine_name = (top50_machine["name"] || top50_machine.try(:name)).to_s.presence || (top50_machine.try(:top50_organization).try(:name)).to_s.presence || "н/д"
              machine_key = Stats::Lineage.branch_key_machine_id(machine_id, rating_data[:precedes_map])
              @new_upd_data << {
                edition: top50_date.join("-"),
                list_id: rating_data[:list_id],
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
