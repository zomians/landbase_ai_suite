require "csv"

namespace :migrate do
  # ============================================================
  # rake migrate:journal_entries
  # Google Sheets（銀行取引CSV）から仕訳データをPostgreSQLへ移行
  # ============================================================
  desc "Google SheetsのCSVから仕訳データをPostgreSQLへ移行する"
  task journal_entries: :environment do
    client_code = ENV.fetch("CLIENT_CODE") { abort "ERROR: CLIENT_CODE 環境変数が必要です" }
    dry_run     = ENV["DRY_RUN"] == "1"
    csv_path    = ENV.fetch("CSV_PATH", Rails.root.join("tmp/journal_entries.csv").to_s)

    abort "ERROR: クライアント '#{client_code}' が見つかりません" unless (client = Client.find_by(code: client_code))
    abort "ERROR: CSVファイルが見つかりません: #{csv_path}" unless File.exist?(csv_path)

    puts "=== 仕訳データ移行 ==="
    puts "クライアント : #{client.name} (#{client.code})"
    puts "CSVパス      : #{csv_path}"
    puts "DRY RUN      : #{dry_run ? 'ON（DB書き込みなし）' : 'OFF'}"
    puts ""

    imported_count  = 0
    skipped_count   = 0
    error_count     = 0
    total_amount    = 0
    errors_detail   = []

    csv_rows = CSV.read(csv_path, headers: true, encoding: "UTF-8")

    csv_rows.each_with_index do |row, idx|
      line_no = idx + 2  # ヘッダー行を除いた行番号

      begin
        date          = Date.parse(row["取引日"].to_s.strip)
        debit_amount  = row["借方金額(円)"].to_s.strip.gsub(/,/, "").to_i
        description   = row["摘要"].to_s.strip
        source_period = date.strftime("%Y-%m")

        # 冪等性チェック: 日付 + 借方金額 + 摘要の組み合わせで重複判定
        duplicate = JournalEntry
          .for_client(client_code)
          .joins(:journal_entry_lines)
          .where(
            date: date,
            description: description,
            source_type: "bank",
            journal_entry_lines: { side: "debit", amount: debit_amount }
          )
          .exists?

        if duplicate
          skipped_count += 1
          next
        end

        total_amount += debit_amount

        unless dry_run
          JournalEntry.transaction do
            credit_amount = row["貸方金額(円)"].to_s.strip.gsub(/,/, "").to_i

            entry = JournalEntry.new(
              client:        client,
              source_type:   "bank",
              source_period: source_period,
              transaction_no: row["取引No"].to_s.strip.presence&.to_i,
              date:          date,
              description:   description,
              tag:           row["タグ"].to_s.strip,
              memo:          row["メモ"].to_s.strip,
              status:        "ok"
            )

            entry.journal_entry_lines.build(
              side:         "debit",
              account:      row["借方勘定科目"].to_s.strip,
              sub_account:  row["借方補助科目"].to_s.strip,
              department:   row["借方部門"].to_s.strip,
              partner:      row["借方取引先"].to_s.strip,
              tax_category: row["借方税区分"].to_s.strip,
              invoice:      row["借方インボイス"].to_s.strip,
              amount:       debit_amount
            )

            entry.journal_entry_lines.build(
              side:         "credit",
              account:      row["貸方勘定科目"].to_s.strip,
              sub_account:  row["貸方補助科目"].to_s.strip,
              department:   row["貸方部門"].to_s.strip,
              partner:      row["貸方取引先"].to_s.strip,
              tax_category: row["貸方税区分"].to_s.strip,
              invoice:      row["貸方インボイス"].to_s.strip,
              amount:       credit_amount
            )

            entry.save!
          end
        end

        imported_count += 1
      rescue ActiveRecord::RecordInvalid, ArgumentError => e
        error_count += 1
        errors_detail << "行 #{line_no}: #{e.message}"
      end
    end

    puts "=== 突合レポート ==="
    puts "取込件数   : #{imported_count} 件#{dry_run ? '（DRY RUN）' : ''}"
    puts "スキップ   : #{skipped_count} 件（重複）"
    puts "エラー     : #{error_count} 件"
    puts "合計金額   : #{total_amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} 円"
    if errors_detail.any?
      puts ""
      puts "=== エラー詳細 ==="
      errors_detail.each { |e| puts e }
    end
  end

  # ============================================================
  # rake migrate:account_masters
  # Google Sheets（勘定科目マスタCSV）からaccount_mastersへ移行
  # ============================================================
  desc "Google Sheetsの勘定科目マスタCSVをPostgreSQLへ移行する"
  task account_masters: :environment do
    client_code = ENV.fetch("CLIENT_CODE") { abort "ERROR: CLIENT_CODE 環境変数が必要です" }
    dry_run     = ENV["DRY_RUN"] == "1"
    csv_path    = ENV.fetch("CSV_PATH", Rails.root.join("tmp/account_masters.csv").to_s)

    abort "ERROR: クライアント '#{client_code}' が見つかりません" unless (client = Client.find_by(code: client_code))
    abort "ERROR: CSVファイルが見つかりません: #{csv_path}" unless File.exist?(csv_path)

    puts "=== 勘定科目マスタ移行 ==="
    puts "クライアント : #{client.name} (#{client.code})"
    puts "CSVパス      : #{csv_path}"
    puts "DRY RUN      : #{dry_run ? 'ON（DB書き込みなし）' : 'OFF'}"
    puts ""

    imported_count = 0
    skipped_count  = 0
    error_count    = 0
    errors_detail  = []

    csv_rows = CSV.read(csv_path, headers: true, encoding: "UTF-8")

    csv_rows.each_with_index do |row, idx|
      line_no          = idx + 2
      merchant_keyword = row["merchant_keyword"].to_s.strip
      account_category = row["account_category"].to_s.strip

      begin
        # 冪等性チェック: merchant_keyword + account_categoryで重複判定
        duplicate = AccountMaster
          .for_client(client_code)
          .where(merchant_keyword: merchant_keyword, account_category: account_category)
          .exists?

        if duplicate
          skipped_count += 1
          next
        end

        unless dry_run
          AccountMaster.create!(
            client:               client,
            source_type:          "receipt",
            merchant_keyword:     merchant_keyword.presence,
            description_keyword:  row["description_keyword"].to_s.strip.presence,
            account_category:     account_category,
            confidence_score:     row["confidence_score"].to_s.strip.presence&.to_i || 50
          )
        end

        imported_count += 1
      rescue ActiveRecord::RecordInvalid, ArgumentError => e
        error_count += 1
        errors_detail << "行 #{line_no}: #{e.message}"
      end
    end

    puts "=== 突合レポート ==="
    puts "取込件数 : #{imported_count} 件#{dry_run ? '（DRY RUN）' : ''}"
    puts "スキップ : #{skipped_count} 件（重複）"
    puts "エラー   : #{error_count} 件"
    if errors_detail.any?
      puts ""
      puts "=== エラー詳細 ==="
      errors_detail.each { |e| puts e }
    end
  end
end
