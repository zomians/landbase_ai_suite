require 'rails_helper'

RSpec.describe "Web::JournalEntries", type: :request do
  let(:user) { create(:user) }
  let(:client) { create(:client, code: "test_client", name: "テスト社") }

  describe "GET /journal_entries" do
    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get journal_entries_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "client_code未指定の場合クライアント一覧にリダイレクトすること" do
        get journal_entries_path
        expect(response).to redirect_to(clients_path)
      end

      it "client_codeが空文字の場合クライアント一覧にリダイレクトすること" do
        get journal_entries_path(client_code: "")
        expect(response).to redirect_to(clients_path)
      end

      it "存在しないclient_codeの場合クライアント一覧にリダイレクトすること" do
        get journal_entries_path(client_code: "nonexistent")
        expect(response).to redirect_to(clients_path)
      end

      it "有効なclient_codeで200を返すこと" do
        get journal_entries_path(client_code: client.code)
        expect(response).to have_http_status(:ok)
      end

      it "パンくずが表示されること" do
        get journal_entries_path(client_code: client.code)
        expect(response.body).to include("クライアント一覧")
        expect(response.body).to include("テスト社")
        expect(response.body).to include("仕訳一覧")
      end

      it "21データカラムがCSV_HEADERSの順序で表示されること" do
        create(:journal_entry, client: client)
        get journal_entries_path(client_code: client.code)

        expect(response).to have_http_status(:ok)
        body = response.body

        expected_headers = [
          "No", "取引日",
          "借方勘定科目", "借方補助科目", "借方部門", "借方取引先", "借方税区分", "借方インボイス", "借方金額(円)",
          "貸方勘定科目", "貸方補助科目", "貸方部門", "貸方取引先", "貸方税区分", "貸方インボイス", "貸方金額(円)",
          "摘要", "タグ", "メモ", "カード利用者", "ステータス"
        ]
        expected_headers.each do |header|
          expect(body).to include(header), "ヘッダー「#{header}」が表示されていません"
        end
      end

      it "空のフィールドに「—」が表示されること" do
        create(:journal_entry, client: client, debit_sub_account: "", debit_department: "")
        get journal_entries_path(client_code: client.code)

        expect(response.body).to include("—")
      end
    end
  end

  describe "GET /journal_entries/:id" do
    let(:entry) { create(:journal_entry, client: client) }

    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get journal_entry_path(entry, client_code: client.code)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "200を返すこと" do
        get journal_entry_path(entry, client_code: client.code)
        expect(response).to have_http_status(:ok)
      end

      it "パンくずが表示されること" do
        get journal_entry_path(entry, client_code: client.code)
        expect(response.body).to include("クライアント一覧")
        expect(response.body).to include("テスト社")
        expect(response.body).to include("仕訳一覧")
      end
    end
  end

  describe "GET /journal_entries/:id/edit" do
    let(:entry) { create(:journal_entry, client: client) }

    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get edit_journal_entry_path(entry, client_code: client.code)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "200を返すこと" do
        get edit_journal_entry_path(entry, client_code: client.code)
        expect(response).to have_http_status(:ok)
      end

      it "パンくずが表示されること" do
        get edit_journal_entry_path(entry, client_code: client.code)
        expect(response.body).to include("クライアント一覧")
        expect(response.body).to include("テスト社")
      end
    end
  end
end
