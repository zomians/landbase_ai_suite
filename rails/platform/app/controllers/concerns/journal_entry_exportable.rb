module JournalEntryExportable
  extend ActiveSupport::Concern

  private

  def send_journal_csv(entries, format_type:)
    case format_type
    when "yayoi_single"
      csv_data = YayoiExportService.new.export_single_entry(entries)
      send_data csv_data,
                filename: "journal_entries_yayoi_single_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv",
                type: "text/csv; charset=shift_jis"
    else
      csv = "\uFEFF" + entries.to_csv
      send_data csv, filename: "journal_entries_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv",
                     type: "text/csv; charset=utf-8"
    end
  end
end
