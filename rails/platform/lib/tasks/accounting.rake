namespace :accounting do
  desc "Google Sheetsから勘定科目マスターをPostgreSQLに移行"
  task migrate_account_masters: :environment do
    # TODO: Google Sheets APIクライアントの初期化
    # google-drive-ruby gem等を追加後に実装
    #
    # 使用例:
    #   session = GoogleDrive::Session.from_service_account_key("credentials.json")
    #   spreadsheet = session.spreadsheet_by_key(ENV["ACCOUNT_MASTER_SHEET_ID"])
    #   worksheet = spreadsheet.worksheets.first

    puts "=== 勘定科目マスター移行開始 ==="

    # TODO: Google Sheetsからデータ取得
    # rows = worksheet.rows.drop(1) # ヘッダー行をスキップ
    rows = [] # Google Sheets API接続後に置き換え

    imported = 0
    skipped = 0
    errors = 0

    rows.each_with_index do |row, index|
      client_code = row[0] # TODO: シート構造に合わせて調整
      merchant_keyword = row[1]
      account_category = row[2]

      # 冪等性チェック: client_code + merchant_keyword + account_category で同一レコード判定
      existing = AccountMaster.find_by(
        client_code: client_code,
        merchant_keyword: merchant_keyword,
        account_category: account_category
      )

      if existing
        skipped += 1
        next
      end

      begin
        AccountMaster.create!(
          client_code: client_code,
          merchant_keyword: merchant_keyword,
          description_keyword: row[3],
          account_category: account_category,
          confidence_score: row[4].present? ? row[4].to_i : 50,
          last_used_date: row[5].present? ? Date.parse(row[5]) : nil,
          usage_count: row[6].present? ? row[6].to_i : 0,
          auto_learned: row[7] == "true",
          notes: row[8] || ""
        )
        imported += 1
      rescue StandardError => e
        errors += 1
        Rails.logger.error "[accounting:migrate_account_masters] 行#{index + 2}でエラー: #{e.message}"
        puts "  エラー (行#{index + 2}): #{e.message}"
      end
    end

    puts "=== 勘定科目マスター移行完了 ==="
    puts "  インポート: #{imported}件"
    puts "  スキップ（重複）: #{skipped}件"
    puts "  エラー: #{errors}件"
  end

  desc "Google Sheetsから仕訳データをPostgreSQLに移行"
  task migrate_journal_entries: :environment do
    # TODO: Google Sheets APIクライアントの初期化
    # google-drive-ruby gem等を追加後に実装
    #
    # 使用例:
    #   session = GoogleDrive::Session.from_service_account_key("credentials.json")
    #   spreadsheet = session.spreadsheet_by_key(ENV["JOURNAL_ENTRIES_SHEET_ID"])
    #   worksheet = spreadsheet.worksheets.first

    puts "=== 仕訳データ移行開始 ==="

    # TODO: Google Sheetsからデータ取得
    # rows = worksheet.rows.drop(1) # ヘッダー行をスキップ
    rows = [] # Google Sheets API接続後に置き換え

    imported = 0
    skipped = 0
    errors = 0

    rows.each_with_index do |row, index|
      client_code = row[0] # TODO: シート構造に合わせて調整
      source_type = row[1]
      source_period = row[2]
      transaction_no = row[3].present? ? row[3].to_i : nil

      # 冪等性チェック: client_code + source_type + source_period + transaction_no で同一レコード判定
      existing = JournalEntry.find_by(
        client_code: client_code,
        source_type: source_type,
        source_period: source_period,
        transaction_no: transaction_no
      )

      if existing
        skipped += 1
        next
      end

      begin
        JournalEntry.create!(
          client_code: client_code,
          source_type: source_type,
          source_period: source_period,
          transaction_no: transaction_no,
          date: Date.parse(row[4]),
          debit_account: row[5],
          debit_sub_account: row[6] || "",
          debit_department: row[7] || "",
          debit_partner: row[8] || "",
          debit_tax_category: row[9] || "",
          debit_invoice: row[10] || "",
          debit_amount: row[11].to_i,
          credit_account: row[12],
          credit_sub_account: row[13] || "",
          credit_department: row[14] || "",
          credit_partner: row[15] || "",
          credit_tax_category: row[16] || "",
          credit_invoice: row[17] || "",
          credit_amount: row[18].to_i,
          description: row[19] || "",
          tag: row[20] || "",
          memo: row[21] || "",
          status: row[22] || "ok"
        )
        imported += 1
      rescue StandardError => e
        errors += 1
        Rails.logger.error "[accounting:migrate_journal_entries] 行#{index + 2}でエラー: #{e.message}"
        puts "  エラー (行#{index + 2}): #{e.message}"
      end
    end

    puts "=== 仕訳データ移行完了 ==="
    puts "  インポート: #{imported}件"
    puts "  スキップ（重複）: #{skipped}件"
    puts "  エラー: #{errors}件"
  end
end
