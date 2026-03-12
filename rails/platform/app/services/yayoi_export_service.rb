require "csv"

class YayoiExportService
  SINGLE_ENTRY_FLAG = "2000"
  SINGLE_TYPE = "0"

  def export_single_entry(entries)
    csv_string = CSV.generate do |csv|
      entries.each do |entry|
        csv << build_row(entry)
      end
    end

    csv_string.encode("Windows-31J", "UTF-8", undef: :replace, invalid: :replace)
  end

  private

  def build_row(entry)
    debit  = entry.debit_lines.first
    credit = entry.credit_lines.first

    [
      SINGLE_ENTRY_FLAG,                       # 1: 識別フラグ
      entry.date.strftime("%Y/%m/%d"),         # 2: 取引日
      debit&.account || "",                    # 3: 借方勘定科目
      debit&.sub_account.presence || "",       # 4: 借方補助科目
      debit&.department.presence || "",        # 5: 借方部門
      debit&.partner.presence || "",           # 6: 借方取引先
      debit&.tax_category.presence || "",      # 7: 借方税区分
      debit&.invoice.presence || "",           # 8: 借方インボイス
      debit&.amount || 0,                      # 9: 借方金額
      credit&.account || "",                   # 10: 貸方勘定科目
      credit&.sub_account.presence || "",      # 11: 貸方補助科目
      credit&.department.presence || "",       # 12: 貸方部門
      credit&.partner.presence || "",          # 13: 貸方取引先
      credit&.tax_category.presence || "",     # 14: 貸方税区分
      credit&.invoice.presence || "",          # 15: 貸方インボイス
      credit&.amount || 0,                     # 16: 貸方金額
      entry.description.presence || "",        # 17: 摘要
      entry.tag.presence || "",                # 18: タグ
      entry.memo.presence || "",               # 19: メモ
      SINGLE_TYPE,                             # 20: タイプ
      "",                                      # 21: 調整フラグ
      "",                                      # 22: 予備1
      "",                                      # 23: 予備2
      "",                                      # 24: 予備3
      ""                                       # 25: 予備4
    ]
  end
end
