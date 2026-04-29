require "set"

module Stats
  module Sections
    class JsonPayloadBuilder
      def initialize(context:, params:)
        @context = context
        @params = params
      end

      def call(section)
        case section
        when "fr_comp_lag"
          payload_for_fr_comp_lag
        when "ram_stats"
          payload_for_ram_stats
        when "comp_stats"
          payload_for_comp_stats
        when "fr_comp_stats"
          payload_for_fr_comp_stats
        when "new_upg"
          payload_for_new_upg
        when "list_upg"
          payload_for_list_upg
        when "area_upg"
          payload_for_area_upg
        else
          nil
        end
      end

      private

      attr_reader :context, :params

      def parse_i(val, default)
        v = val.to_i
        v > 0 ? v : default
      end

      def requested_datasets
        raw = params[:datasets]
        return nil if raw.blank?

        raw.to_s.split(",").map { |s| s.strip }.reject(&:blank?).to_set
      end

      def include_dataset?(requested, key)
        requested.nil? || requested.include?(key)
      end

      def default_max_rank
        context.instance_variable_get(:@max_rank) || context.class::TOP50_MAX_RANK
      end

      def filter_by_ranges(arr, ed_from, ed_to, rk_from, rk_to)
        (arr || []).select do |h|
          ed = h[:edition] || h["edition"]
          rk = h[:rank] || h["rank"]
          ed && rk && ed >= ed_from && ed <= ed_to && rk >= rk_from && rk <= rk_to
        end
      end

      def filter_by_editions(arr, ed_from, ed_to)
        (arr || []).select do |h|
          ed = h[:edition] || h["edition"]
          ed && ed >= ed_from && ed <= ed_to
        end
      end

      def payload_for_fr_comp_lag
        max_edition = (context.instance_variable_get(:@edition_dates_lag) || []).length
        max_edition = 1 if max_edition <= 0
        ed_from = parse_i(params[:edition_start], 1)
        ed_to = parse_i(params[:edition_end], max_edition)
        ed_from, ed_to = ed_to, ed_from if ed_from > ed_to
        rk_from = parse_i(params[:rank_start], 1)
        rk_to = parse_i(params[:rank_end], default_max_rank)
        rk_from, rk_to = rk_to, rk_from if rk_from > rk_to

        requested = requested_datasets
        payload = {
          edition_dates: context.instance_variable_get(:@edition_dates_lag) || [],
          edition_start: ed_from,
          edition_end: ed_to,
          rank_start: rk_from,
          rank_end: rk_to
        }
        if include_dataset?(requested, "cpu_data")
          payload[:cpu_data] = filter_by_ranges(context.instance_variable_get(:@cpu_data), ed_from, ed_to, rk_from, rk_to)
        end
        if include_dataset?(requested, "gpu_data")
          payload[:gpu_data] = filter_by_ranges(context.instance_variable_get(:@gpu_data), ed_from, ed_to, rk_from, rk_to)
        end
        if include_dataset?(requested, "combined_data")
          payload[:combined_data] = filter_by_ranges(context.instance_variable_get(:@combined_data), ed_from, ed_to, rk_from, rk_to)
        end
        payload
      end

      def payload_for_ram_stats
        max_edition = (context.instance_variable_get(:@edition_dates_ram) || []).length
        max_edition = 1 if max_edition <= 0
        ed_from = parse_i(params[:edition_start], 1)
        ed_to = parse_i(params[:edition_end], max_edition)
        ed_from, ed_to = ed_to, ed_from if ed_from > ed_to
        rk_from = parse_i(params[:rank_start], 1)
        rk_to = parse_i(params[:rank_end], default_max_rank)
        rk_from, rk_to = rk_to, rk_from if rk_from > rk_to

        requested = requested_datasets
        payload = {
          edition_dates: context.instance_variable_get(:@edition_dates_ram) || [],
          edition_start: ed_from,
          edition_end: ed_to,
          rank_start: rk_from,
          rank_end: rk_to
        }
        if include_dataset?(requested, "ram_per_core_data")
          payload[:ram_per_core_data] = filter_by_ranges(context.instance_variable_get(:@ram_per_core_data), ed_from, ed_to, rk_from, rk_to)
        end
        if include_dataset?(requested, "ram_per_cpu_data")
          payload[:ram_per_cpu_data] = filter_by_ranges(context.instance_variable_get(:@ram_per_cpu_data), ed_from, ed_to, rk_from, rk_to)
        end
        if include_dataset?(requested, "ram_per_node_data")
          payload[:ram_per_node_data] = filter_by_ranges(context.instance_variable_get(:@ram_per_node_data), ed_from, ed_to, rk_from, rk_to)
        end
        payload
      end

      def payload_for_comp_stats
        max_edition = (context.instance_variable_get(:@edition_dates_component) || []).length
        max_edition = 1 if max_edition <= 0
        ed_from = parse_i(params[:edition_start], 1)
        ed_to = parse_i(params[:edition_end], max_edition)
        ed_from, ed_to = ed_to, ed_from if ed_from > ed_to
        rk_from = parse_i(params[:rank_start], 1)
        rk_to = parse_i(params[:rank_end], default_max_rank)
        rk_from, rk_to = rk_to, rk_from if rk_from > rk_to
        wrap = ->(arr) { filter_by_ranges(arr, ed_from, ed_to, rk_from, rk_to) }
        requested = requested_datasets
        payload = {
          edition_dates: context.instance_variable_get(:@edition_dates_component) || [],
          edition_start: ed_from,
          edition_end: ed_to,
          rank_start: rk_from,
          rank_end: rk_to
        }
        datasets = {
          cpu_total_data: :@cpu_total_data,
          cpu_per_node_data: :@cpu_per_node_data,
          gpu_total_data: :@gpu_total_data,
          gpu_per_node_data: :@gpu_per_node_data,
          freshest_total_data: :@freshest_total_data,
          freshest_per_node_data: :@freshest_per_node_data,
          freshest_total_data_cpu_only: :@freshest_total_data_cpu_only,
          freshest_per_node_data_cpu_only: :@freshest_per_node_data_cpu_only,
          cores_total_data: :@cores_total_data,
          cores_per_node_data: :@cores_per_node_data,
          gpu_cores_total_data: :@gpu_cores_total_data,
          gpu_cores_per_node_data: :@gpu_cores_per_node_data,
          gpu_microcores_only_total_data: :@gpu_microcores_only_total_data,
          gpu_microcores_only_per_node_data: :@gpu_microcores_only_per_node_data
        }
        datasets.each do |key, ivar|
          next unless include_dataset?(requested, key.to_s)

          payload[key] = wrap.call(context.instance_variable_get(ivar))
        end
        payload
      end

      def payload_for_fr_comp_stats
        edition_dates = context.instance_variable_get(:@edition_dates_freshest_quantity) || []
        max_edition = edition_dates.length
        max_edition = 1 if max_edition <= 0
        ed_from = parse_i(params[:edition_start], 1)
        ed_to = parse_i(params[:edition_end], max_edition)
        ed_from, ed_to = ed_to, ed_from if ed_from > ed_to
        wrap_ed = ->(arr) { filter_by_editions(arr, ed_from, ed_to) }

        requested = requested_datasets
        payload = {
          edition_dates: edition_dates,
          edition_start: ed_from,
          edition_end: ed_to
        }
        if include_dataset?(requested, "freshest_cpu_quantity_data")
          payload[:freshest_cpu_quantity_data] = wrap_ed.call(context.instance_variable_get(:@freshest_cpu_quantity_data))
        end
        if include_dataset?(requested, "freshest_gpu_quantity_data")
          payload[:freshest_gpu_quantity_data] = wrap_ed.call(context.instance_variable_get(:@freshest_gpu_quantity_data))
        end
        if include_dataset?(requested, "announce_to_mention_cpu_data")
          payload[:announce_to_mention_cpu_data] = wrap_ed.call(context.instance_variable_get(:@announce_to_mention_cpu_data))
        end
        if include_dataset?(requested, "announce_to_mention_gpu_data")
          payload[:announce_to_mention_gpu_data] = wrap_ed.call(context.instance_variable_get(:@announce_to_mention_gpu_data))
        end
        payload
      end

      def payload_for_new_upg
        requested = requested_datasets
        payload = {}
        if include_dataset?(requested, "ratings_chart_data")
          payload[:ratings_chart_data] = context.instance_variable_get(:@ratings_chart_data)
        end
        if include_dataset?(requested, "ratings_rpeak_pct_chart_data")
          payload[:ratings_rpeak_pct_chart_data] = context.instance_variable_get(:@ratings_rpeak_pct_chart_data)
        end
        if include_dataset?(requested, "ratings_rmax_pct_chart_data")
          payload[:ratings_rmax_pct_chart_data] = context.instance_variable_get(:@ratings_rmax_pct_chart_data)
        end
        payload
      end

      def payload_for_list_upg
        rk_from = parse_i(params[:rank_start], 1)
        rk_to = parse_i(params[:rank_end], default_max_rank)
        rk_from, rk_to = rk_to, rk_from if rk_from > rk_to

        all_data = context.instance_variable_get(:@new_upd_data) || []
        all_editions = all_data.map { |e| e[:edition] }.uniq.sort
        ed_from = params[:edition_start]
        ed_to = params[:edition_end]
        if ed_from.present? && ed_to.present?
          from_idx = all_editions.index(ed_from) || 0
          to_idx = all_editions.index(ed_to) || all_editions.length - 1
          from_idx, to_idx = to_idx, from_idx if from_idx > to_idx
          allowed_editions = all_editions[from_idx..to_idx]
        else
          allowed_editions = all_editions
        end

        matrix_entries = all_data.select do |e|
          rk = e[:rank]
          allowed_editions.include?(e[:edition]) && rk && rk >= rk_from && rk <= rk_to
        end

        {
          matrix_data: matrix_entries,
          editions: all_editions,
          rank_start: rk_from,
          rank_end: rk_to
        }
      end

      def payload_for_area_upg
        requested = requested_datasets
        payload = {}
        if include_dataset?(requested, "area_upg_lag_by_edition")
          payload[:area_upg_lag_by_edition] = context.instance_variable_get(:@area_upg_lag_by_edition) || []
        end
        if include_dataset?(requested, "area_upg_new_qty_by_edition")
          payload[:area_upg_new_qty_by_edition] = context.instance_variable_get(:@area_upg_new_qty_by_edition) || []
        end
        if include_dataset?(requested, "area_upg_systems_with_new_by_edition")
          payload[:area_upg_systems_with_new_by_edition] = context.instance_variable_get(:@area_upg_systems_with_new_by_edition) || []
        end
        if include_dataset?(requested, "area_upg_new_upgraded_by_edition")
          payload[:area_upg_new_upgraded_by_edition] = context.instance_variable_get(:@area_upg_new_upgraded_by_edition) || []
        end
        if include_dataset?(requested, "area_upg_edition_labels")
          payload[:area_upg_edition_labels] = context.instance_variable_get(:@area_upg_edition_labels) || []
        end
        payload
      end
    end
  end
end
