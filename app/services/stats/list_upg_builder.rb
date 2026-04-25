module Stats
  class ListUpgBuilder
    def initialize(new_upd_data:, top50_slists:, num_vals:, max_rank:)
      @new_upd_data = new_upd_data
      @top50_slists = top50_slists
      @num_vals = num_vals
      @max_rank = max_rank
    end

    def call
      sorted_data = @new_upd_data.sort_by { |entry| [-entry[:edition].split("-").join.to_i, entry[:rank]] }
      lists_chronological = @top50_slists.reverse
      new_upd_list_ids = lists_chronological.map(&:id)
      new_upd_list_nums = new_upd_list_ids.map { |lid| @num_vals.find_by(obj_id: lid)&.value.presence || "—" }
      entry_by_rank_and_list = sorted_data.each_with_object({}) { |e, h| h[[e[:rank], e[:list_id]]] = e }
      matrix = (1..@max_rank).map do |rank|
        new_upd_list_ids.map { |list_id| entry_by_rank_and_list[[rank, list_id]] }
      end

      {
        new_upd_data: sorted_data,
        new_upd_data_2d: sorted_data.group_by { |entry| entry[:edition] }.values,
        new_upd_list_ids: new_upd_list_ids,
        new_upd_list_nums: new_upd_list_nums,
        new_upd_matrix: matrix,
        csv_string_list_upg: build_csv(matrix),
        chart_data_json: build_chart_data_json(sorted_data)
      }
    end

    private

    def build_csv(matrix)
      col_headers = (1..matrix.first.to_a.size).to_a
      csv_lines = col_headers.present? ? ["Место | Редакция," + col_headers.join(",")] : []
      matrix.each_with_index do |row, idx|
        row_str = (idx + 1).to_s
        row.each do |entry|
          cell = if entry.present?
            statuses = []
            statuses << (entry[:new_upd_status] == "updated" ? "upg" : entry[:new_upd_status]) if entry[:new_upd_status].present?
            statuses << "+#{entry[:rank_change]}" if entry[:pos_status] == "moved_up" && entry[:rank_change].present?
            statuses << "-#{entry[:rank_change].abs}" if entry[:pos_status] == "moved_down" && entry[:rank_change].present?
            statuses.present? ? statuses.join(" ") : ""
          else
            ""
          end
          cell_str = cell.to_s.include?(",") ? "\"#{cell.to_s.gsub('"', '""')}\"" : cell.to_s
          row_str += "," + cell_str
        end
        csv_lines << row_str if csv_lines.present?
      end
      csv_lines
    end

    def build_chart_data_json(sorted_data)
      sorted_data.map do |entry|
        {
          edition: entry[:edition],
          list_num: entry[:list_num],
          rank: entry[:rank],
          new_upd_status: entry[:new_upd_status],
          pos_status: entry[:pos_status],
          rank_change: entry[:rank_change],
          machine_id: entry[:machine_id],
          machine_name: entry[:machine_name],
          machine_key: entry[:machine_key],
          area_name: entry[:area_name],
          area_color: entry[:area_color]
        }
      end.to_json
    end
  end
end
