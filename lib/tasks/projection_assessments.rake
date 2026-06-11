require "csv"

namespace :projection_assessments do
  desc "Backtest projections for EVENTS and export results to CSV"
  task export: :environment do
    event_slugs = ENV["EVENTS"].to_s.split(",").map(&:strip).reject(&:empty?)
    completed_split_name = ENV.fetch("COMPLETED_SPLIT", nil)
    projected_split_name = ENV.fetch("PROJECTED_SPLIT", nil)

    if event_slugs.empty? || completed_split_name.blank? || projected_split_name.blank?
      abort(<<~USAGE)
        Usage:
          EVENTS=<slug>[,<slug>...] COMPLETED_SPLIT=<base name> PROJECTED_SPLIT=<base name> \\
          [COMPLETED_SUB_SPLIT=out] [PROJECTED_SUB_SPLIT=in] [LAP=1] [OUTPUT=<path>] \\
          bin/rails projection_assessments:export
      USAGE
    end

    completed_bitkey = SubSplit.bitkey(ENV.fetch("COMPLETED_SUB_SPLIT", "out")) || abort("Invalid COMPLETED_SUB_SPLIT")
    projected_bitkey = SubSplit.bitkey(ENV.fetch("PROJECTED_SUB_SPLIT", "in")) || abort("Invalid PROJECTED_SUB_SPLIT")
    lap = ENV.fetch("LAP", "1").to_i
    output_path = ENV["OUTPUT"].presence ||
                  Rails.root.join("tmp", "projection_assessments_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv").to_s

    ActiveRecord::Base.logger.silence do
      runs = event_slugs.map do |slug|
        event = ::Event.friendly.find(slug)
        completed_split = event.splits.find_by(parameterized_base_name: completed_split_name.parameterize) ||
                          abort("Event #{slug} has no split named #{completed_split_name}")
        projected_split = event.splits.find_by(parameterized_base_name: projected_split_name.parameterize) ||
                          abort("Event #{slug} has no split named #{projected_split_name}")

        run = event.projection_assessment_runs.create!(
          completed_lap: lap,
          completed_split: completed_split,
          completed_bitkey: completed_bitkey,
          projected_lap: lap,
          projected_split: projected_split,
          projected_bitkey: projected_bitkey,
        )

        efforts_count = event.efforts.count
        puts "Assessing #{slug}: #{completed_split.base_name} #{SubSplit.kind(completed_bitkey)} -> " \
             "#{projected_split.base_name} #{SubSplit.kind(projected_bitkey)} (#{efforts_count} efforts)"
        progress_bar = ::ProgressBar.new(efforts_count)
        ::ProjectionAssessments::Runner.perform!(run) { progress_bar.increment! }
        puts "  #{run.status}: #{run.success_count.to_i} succeeded, #{run.failure_count.to_i} failed " \
             "in #{run.elapsed_time.to_i} seconds"
        warn "  errors: #{run.parsed_errors.join('; ')}" if run.failed?
        run
      end

      rows = runs.flat_map do |run|
        event = run.event
        time_zone = event.home_time_zone
        year = event.scheduled_start_time.in_time_zone(time_zone).year

        run.assessments.includes(:effort).reject { |a| a.projected_early.blank? && a.actual.blank? }.map do |assessment|
          [
            assessment.effort.full_name,
            year,
            assessment.projected_early&.in_time_zone(time_zone)&.strftime("%Y-%m-%d %H:%M:%S"),
            assessment.actual&.in_time_zone(time_zone)&.strftime("%Y-%m-%d %H:%M:%S"),
          ]
        end
      end

      CSV.open(output_path, "w") do |csv|
        csv << ["Runner name", "Race year", "Earliest predicted arrival", "Actual arrival"]
        rows.sort_by { |row| [row[1], row[0]] }.each { |row| csv << row }
      end

      puts "Wrote #{rows.size} rows to #{output_path}"
    end
  end
end
