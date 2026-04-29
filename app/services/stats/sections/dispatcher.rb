module Stats
  module Sections
    class Dispatcher
      SECTION_SERVICES = {
        "fr_comp_lag" => "Stats::Sections::FrCompLagService",
        "new_upg" => "Stats::Sections::NewUpgService",
        "ram_stats" => "Stats::Sections::RamStatsService",
        "comp_stats" => "Stats::Sections::CompStatsService",
        "fr_comp_stats" => "Stats::Sections::FrCompStatsService",
        "area_upg" => "Stats::Sections::AreaUpgService",
        "list_upg" => "Stats::Sections::ListUpgService"
      }.freeze

      def initialize(context:)
        @context = context
      end

      def call(section_key)
        class_name = SECTION_SERVICES[section_key]
        return false unless class_name

        class_name.constantize.new(context: @context).call
        true
      end
    end
  end
end
