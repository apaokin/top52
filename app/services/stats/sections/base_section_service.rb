module Stats
  module Sections
    class BaseSectionService
      def initialize(context:)
        @context = context
      end

      private

      attr_reader :context

      def run_in_context(&block)
        context.instance_eval(&block)
      end

      def ensure_machine_attrs!
        run_in_context { calc_machine_attrs }
      end

      def top50_lists_sorted
        context.send(:get_top50_lists_sorted)
      end

      def edition_timeline(top50_slists)
        Stats::EditionTimeline.from_lists(
          top50_slists: top50_slists,
          date_vals: context.instance_variable_get(:@date_vals)
        )
      end

      def default_max_rank
        context.instance_variable_get(:@max_rank) || context.class::TOP50_MAX_RANK
      end

      def precedes_map_for_lineage
        Stats::Lineage.precedes_child_to_parent_map
      end

      def lineage_branch_key(machine_id, map = nil)
        Stats::Lineage.branch_key_machine_id(machine_id, map)
      end
    end
  end
end
