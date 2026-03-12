require "rails_helper"
require "rake"

RSpec.describe "migrate rake tasks" do
  # Rakeタスクをテストごとに再ロードするためのヘルパー
  before(:all) do
    Rails.application.load_tasks
  end

  let(:client) { create(:client, name: "テストクライアント1", code: "test_client_1") }

  let(:journal_entries_csv_path) do
    Rails.root.join("spec/fixtures/files/journal_entries.csv").to_s
  end

  let(:account_masters_csv_path) do
    Rails.root.join("spec/fixtures/files/account_masters.csv").to_s
  end

  # Rake タスクの出力を抑制しながら実行するヘルパー
  def run_task(task_name, env_vars = {})
    old_env = {}
    env_vars.each do |key, val|
      old_env[key] = ENV[key]
      ENV[key] = val
    end

    task = Rake::Task[task_name]
    task.reenable
    suppress_output { task.invoke }
  ensure
    old_env.each { |key, val| ENV[key] = val }
  end

  def suppress_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original_stdout
  end

  # ============================================================
  # migrate:journal_entries
  # ============================================================
  describe "migrate:journal_entries" do
    context "正常系" do
      it "CSVの仕訳データをDBに取り込むこと" do
        client  # clientを先に作成

        expect {
          run_task("migrate:journal_entries",
            "CLIENT_CODE" => client.code,
            "CSV_PATH"    => journal_entries_csv_path
          )
        }.to change { JournalEntry.for_client(client.code).count }.by(3)
      end

      it "source_typeが 'bank' で登録されること" do
        client

        run_task("migrate:journal_entries",
          "CLIENT_CODE" => client.code,
          "CSV_PATH"    => journal_entries_csv_path
        )

        expect(
          JournalEntry.for_client(client.code).all? { |e| e.source_type == "bank" }
        ).to be true
      end

      it "source_periodが取引日のYYYY-MM形式で登録されること" do
        client

        run_task("migrate:journal_entries",
          "CLIENT_CODE" => client.code,
          "CSV_PATH"    => journal_entries_csv_path
        )

        periods = JournalEntry.for_client(client.code).pluck(:source_period).uniq
        expect(periods).to all(match(/\A\d{4}-\d{2}\z/))
      end

      it "借方・貸方の明細行が両方登録されること" do
        client

        run_task("migrate:journal_entries",
          "CLIENT_CODE" => client.code,
          "CSV_PATH"    => journal_entries_csv_path
        )

        entry = JournalEntry.for_client(client.code).first
        expect(entry.journal_entry_lines.where(side: "debit").count).to eq(1)
        expect(entry.journal_entry_lines.where(side: "credit").count).to eq(1)
      end
    end

    context "DRY_RUN=1 の場合" do
      it "DBへの書き込みが行われないこと" do
        client

        expect {
          run_task("migrate:journal_entries",
            "CLIENT_CODE" => client.code,
            "CSV_PATH"    => journal_entries_csv_path,
            "DRY_RUN"     => "1"
          )
        }.not_to change { JournalEntry.count }
      end
    end

    context "冪等性" do
      it "同じCSVを2回実行しても重複登録されないこと" do
        client

        run_task("migrate:journal_entries",
          "CLIENT_CODE" => client.code,
          "CSV_PATH"    => journal_entries_csv_path
        )

        expect {
          run_task("migrate:journal_entries",
            "CLIENT_CODE" => client.code,
            "CSV_PATH"    => journal_entries_csv_path
          )
        }.not_to change { JournalEntry.for_client(client.code).count }
      end
    end

    context "CLIENT_CODEが未指定の場合" do
      it "abort で終了すること" do
        expect {
          run_task("migrate:journal_entries",
            "CSV_PATH" => journal_entries_csv_path
          )
        }.to raise_error(SystemExit)
      end
    end

    context "CSVファイルが存在しない場合" do
      it "abort で終了すること" do
        client

        expect {
          run_task("migrate:journal_entries",
            "CLIENT_CODE" => client.code,
            "CSV_PATH"    => "/nonexistent/path/journal_entries.csv"
          )
        }.to raise_error(SystemExit)
      end
    end

    context "存在しないCLIENT_CODEが指定された場合" do
      it "abort で終了すること" do
        expect {
          run_task("migrate:journal_entries",
            "CLIENT_CODE" => "nonexistent_client",
            "CSV_PATH"    => journal_entries_csv_path
          )
        }.to raise_error(SystemExit)
      end
    end
  end

  # ============================================================
  # migrate:account_masters
  # ============================================================
  describe "migrate:account_masters" do
    context "正常系" do
      it "CSVの勘定科目マスタをDBに取り込むこと" do
        client

        expect {
          run_task("migrate:account_masters",
            "CLIENT_CODE" => client.code,
            "CSV_PATH"    => account_masters_csv_path
          )
        }.to change { AccountMaster.for_client(client.code).count }.by(4)
      end

      it "source_typeが 'receipt' で登録されること" do
        client

        run_task("migrate:account_masters",
          "CLIENT_CODE" => client.code,
          "CSV_PATH"    => account_masters_csv_path
        )

        expect(
          AccountMaster.for_client(client.code).all? { |am| am.source_type == "receipt" }
        ).to be true
      end

      it "confidence_scoreが正しく設定されること" do
        client

        run_task("migrate:account_masters",
          "CLIENT_CODE" => client.code,
          "CSV_PATH"    => account_masters_csv_path
        )

        am = AccountMaster.for_client(client.code).find_by(merchant_keyword: "ｵｷﾅﾜﾃﾞﾝﾘﾖｸ")
        expect(am.confidence_score).to eq(90)
      end
    end

    context "DRY_RUN=1 の場合" do
      it "DBへの書き込みが行われないこと" do
        client

        expect {
          run_task("migrate:account_masters",
            "CLIENT_CODE" => client.code,
            "CSV_PATH"    => account_masters_csv_path,
            "DRY_RUN"     => "1"
          )
        }.not_to change { AccountMaster.count }
      end
    end

    context "冪等性" do
      it "同じCSVを2回実行しても重複登録されないこと" do
        client

        run_task("migrate:account_masters",
          "CLIENT_CODE" => client.code,
          "CSV_PATH"    => account_masters_csv_path
        )

        expect {
          run_task("migrate:account_masters",
            "CLIENT_CODE" => client.code,
            "CSV_PATH"    => account_masters_csv_path
          )
        }.not_to change { AccountMaster.for_client(client.code).count }
      end
    end

    context "CLIENT_CODEが未指定の場合" do
      it "abort で終了すること" do
        expect {
          run_task("migrate:account_masters",
            "CSV_PATH" => account_masters_csv_path
          )
        }.to raise_error(SystemExit)
      end
    end

    context "CSVファイルが存在しない場合" do
      it "abort で終了すること" do
        client

        expect {
          run_task("migrate:account_masters",
            "CLIENT_CODE" => client.code,
            "CSV_PATH"    => "/nonexistent/path/account_masters.csv"
          )
        }.to raise_error(SystemExit)
      end
    end
  end
end
