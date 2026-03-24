# encoding: utf-8

require "csv"
require "date"

namespace :import do
  desc "Import component_infos from CSV (set CSV_PATH=...)"
  task :component_infos => :environment do
    default_path = "/app/shared/component_infos.csv"
    csv_path = ENV["CSV_PATH"].to_s.strip
    csv_path = default_path if csv_path.empty?

    unless File.exist?(csv_path)
      puts "CSV file not found: #{csv_path}"
      puts "Pass path as: rake import:component_infos CSV_PATH=/path/to/component_infos.csv"
      exit 1
    end

    puts "CSV path: #{csv_path}"
    print "Continue import and replace rows for listed component_id values? (yes/no): "
    answer = STDIN.gets.to_s.strip.downcase
    unless %w[yes y].include?(answer)
      puts "Import cancelled."
      next
    end

    rows = CSV.read(csv_path, headers: true)
    component_ids = rows.map { |row| row["component_id"].to_i }.uniq
    inserted = 0

    ComponentInfo.transaction do
      ComponentInfo.where(:component_id => component_ids).delete_all

      rows.each_with_index do |row, index|
        component_id = row["component_id"].to_s.strip
        date_announced = row["date_announced"].to_s.strip
        date_mentioned = row["date_mentioned"].to_s.strip

        if component_id.empty? || date_announced.empty?
          raise "Invalid row #{index + 2}: component_id and date_announced are required"
        end

        ComponentInfo.create!(
          :component_id => component_id.to_i,
          :date_announced => Date.parse(date_announced),
          :date_mentioned => date_mentioned.empty? ? nil : Date.parse(date_mentioned)
        )
        inserted += 1
      end
    end

    puts "Inserted #{inserted} rows."
  end
end
