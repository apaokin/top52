module Stats
  class NewUpgBuilder
    def initialize(ratings_summary:, all_ratings_data:, num_vals:, date_vals:)
      @ratings_summary = ratings_summary
      @all_ratings_data = all_ratings_data
      @num_vals = num_vals
      @date_vals = date_vals
    end

    def call
      first_rating = @all_ratings_data[0] || {}
      denom = (first_rating[:machines] || []).size.to_f
      num_by_list_id = @num_vals.pluck(:obj_id, :value).to_h
      date_by_list_id = @date_vals.pluck(:obj_id, :value).to_h
      ratings_summary_for_js = build_summary_for_js(denom, num_by_list_id, date_by_list_id)
      {
        ratings_chart_data: build_count_chart_data,
        ratings_rpeak_pct_chart_data: build_rpeak_pct_chart_data,
        ratings_rmax_pct_chart_data: build_rmax_pct_chart_data,
        edition_dates_new_upg: build_edition_dates,
        ratings_summary_for_js: ratings_summary_for_js,
        ratings_table_rows: ratings_summary_for_js,
        csv_string_new_upg: build_csv_rows(ratings_summary_for_js)
      }
    end

    private

    def build_count_chart_data
      [
        {
          name: "Новые и обновлённые системы",
          data: @ratings_summary.map { |rating| [rating[:date], rating[:total_machines]] },
          color: "#0000FF"
        },
        {
          name: "Новые системы",
          data: @ratings_summary.map { |rating| [rating[:date], rating[:new_machines]] },
          color: "#2ca02c"
        },
        {
          name: "Обновлённые системы",
          data: @ratings_summary.map { |rating| [rating[:date], rating[:upgraded_machines]] },
          color: "#ff7f0e"
        }
      ]
    end

    def build_rpeak_pct_chart_data
      build_pct_chart_data(:sum_rpeak_total, :sum_rpeak_new, :sum_rpeak_upg)
    end

    def build_rmax_pct_chart_data
      build_pct_chart_data(:sum_rmax_total, :sum_rmax_new, :sum_rmax_upg)
    end

    def build_pct_chart_data(total_key, new_key, upg_key)
      [
        {
          name: "Новые и обновлённые системы",
          data: @ratings_summary.map do |r|
            total = r[total_key].to_f
            [r[:date], Stats::Percent.of(r[new_key].to_f + r[upg_key].to_f, total)]
          end,
          color: "#0000FF"
        },
        {
          name: "Новые системы",
          data: @ratings_summary.map do |r|
            total = r[total_key].to_f
            [r[:date], Stats::Percent.of(r[new_key], total)]
          end,
          color: "#2ca02c"
        },
        {
          name: "Обновлённые системы",
          data: @ratings_summary.map do |r|
            total = r[total_key].to_f
            [r[:date], Stats::Percent.of(r[upg_key], total)]
          end,
          color: "#ff7f0e"
        }
      ]
    end

    def build_edition_dates
      @ratings_summary.map do |s|
        parts = s[:date].to_s.split("-")
        parts.size >= 2 ? "#{parts[1]}.#{parts[0][-2..-1]}" : s[:date].to_s
      end
    end

    def build_summary_for_js(denom, num_by_list_id = nil, date_by_list_id = nil)
      num_by_list_id ||= @num_vals.pluck(:obj_id, :value).to_h
      date_by_list_id ||= @date_vals.pluck(:obj_id, :value).to_h
      @ratings_summary.each_with_index.map do |s, idx|
        date_val = date_by_list_id[s[:list_id]]
        list_num = num_by_list_id[s[:list_id]]
        edition_label = if list_num.present? && date_val.present?
          "#{list_num}#{8209.chr}я (#{date_val})"
        elsif date_val.present?
          date_val
        else
          s[:date].to_s
        end
        total_mach = s[:new_machines] + s[:upgraded_machines]
        sum_rpeak = s[:sum_rpeak_total].to_f
        sum_rmax = s[:sum_rmax_total].to_f
        {
          edition_index: idx + 1,
          edition_label: edition_label,
          list_num: list_num,
          date_value: date_val,
          new_machines: s[:new_machines],
          upgraded_machines: s[:upgraded_machines],
          total_machines: total_mach,
          pct_new: percent_or_nil(s[:new_machines], denom),
          pct_upg: percent_or_nil(s[:upgraded_machines], denom),
          pct_new_upg: percent_or_nil(total_mach, denom),
          pct_rpeak_new: percent_or_nil(s[:sum_rpeak_new], sum_rpeak),
          pct_rmax_new: percent_or_nil(s[:sum_rmax_new], sum_rmax),
          pct_rpeak_upg: percent_or_nil(s[:sum_rpeak_upg], sum_rpeak),
          pct_rmax_upg: percent_or_nil(s[:sum_rmax_upg], sum_rmax),
          pct_rpeak_new_upg: percent_or_nil(s[:sum_rpeak_new].to_f + s[:sum_rpeak_upg].to_f, sum_rpeak),
          pct_rmax_new_upg: percent_or_nil(s[:sum_rmax_new].to_f + s[:sum_rmax_upg].to_f, sum_rmax)
        }
      end
    end

    def percent_or_nil(part, total)
      return nil if total.to_f <= 0.0

      Stats::Percent.of(part, total)
    end

    def build_csv_rows(rows)
      header = "Редакция,Новые машины,Обновлённые машины,Новые и обновлённые машины,% Новых машин,% Обновлённых машин,% Новых и обновлённых машин,% Rpeak новых машин,% Rmax новых машин,% Rpeak обновлённых машин,% Rmax обновлённых машин,% Rpeak новых и обновлённых машин,% Rmax новых и обновлённых машин"
      csv_rows = [header]
      rows.each do |row|
        csv_rows << [
          row[:edition_label],
          row[:new_machines],
          row[:upgraded_machines],
          row[:total_machines],
          row[:pct_new].to_s,
          row[:pct_upg].to_s,
          row[:pct_new_upg].to_s,
          row[:pct_rpeak_new].to_s,
          row[:pct_rmax_new].to_s,
          row[:pct_rpeak_upg].to_s,
          row[:pct_rmax_upg].to_s,
          row[:pct_rpeak_new_upg].to_s,
          row[:pct_rmax_new_upg].to_s
        ].join(",")
      end
      csv_rows
    end
  end
end
