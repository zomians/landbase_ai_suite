require "csv"

class YayoiExportService
  SINGLE_ENTRY_FLAG = "2000"
  TRANSFER_FIRST_FLAG = "2110"
  TRANSFER_SUBSEQUENT_FLAG = "2101"
  SINGLE_TYPE = "0"
  TRANSFER_TYPE = "3"

  def export_single_entry(entries)
    generate_csv(entries, mode: :single)
  end

  def export_transfer_slip(entries)
    generate_csv(entries, mode: :transfer)
  end

  private

  def generate_csv(entries, mode:)
    csv_string = CSV.generate do |csv|
      entries.each_with_index do |entry, index|
        csv << build_row(entry, mode: mode, index: index)
      end
    end

    csv_string.encode("Shift_JIS", "UTF-8", undef: :replace, invalid: :replace)
  end

  def build_row(entry, mode:, index:)
    flag = resolve_flag(mode, index)
    type = mode == :single ? SINGLE_TYPE : TRANSFER_TYPE

    [
      flag,                                    # 1: 識別フラグ
      entry.date.strftime("%Y/%m/%d"),         # 2: 取引日
      entry.debit_account,                     # 3: 借方勘定科目
      entry.debit_sub_account.presence || "",  # 4: 借方補助科目
      entry.debit_department.presence || "",   # 5: 借方部門
      entry.debit_partner.presence || "",      # 6: 借方取引先
      entry.debit_tax_category.presence || "", # 7: 借方税区分
      entry.debit_invoice.presence || "",      # 8: 借方インボイス
      entry.debit_amount || 0,                 # 9: 借方金額
      entry.credit_account,                    # 10: 貸方勘定科目
      entry.credit_sub_account.presence || "", # 11: 貸方補助科目
      entry.credit_department.presence || "",  # 12: 貸方部門
      entry.credit_partner.presence || "",     # 13: 貸方取引先
      entry.credit_tax_category.presence || "",# 14: 貸方税区分
      entry.credit_invoice.presence || "",     # 15: 貸方インボイス
      entry.credit_amount || 0,               # 16: 貸方金額
      entry.description.presence || "",        # 17: 摘要
      entry.tag.presence || "",                # 18: タグ
      entry.memo.presence || "",               # 19: メモ
      type,                                    # 20: タイプ
      "",                                      # 21: 調整フラグ
      "",                                      # 22: 予備1
      "",                                      # 23: 予備2
      "",                                      # 24: 予備3
      ""                                       # 25: 予備4
    ]
  end

  def resolve_flag(mode, index)
    case mode
    when :single
      SINGLE_ENTRY_FLAG
    when :transfer
      index.zero? ? TRANSFER_FIRST_FLAG : TRANSFER_SUBSEQUENT_FLAG
    end
  end
end
