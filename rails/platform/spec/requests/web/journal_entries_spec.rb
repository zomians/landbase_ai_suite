require 'rails_helper'

RSpec.describe "Web::JournalEntries", type: :request do
  let(:user) { create(:user) }
  let(:client) { create(:client, code: "test_client") }

  describe "GET /journal_entries" do
    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get journal_entries_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "200を返すこと" do
        get journal_entries_path
        expect(response).to have_http_status(:ok)
      end

      it "21データカラムがCSV_HEADERSの順序で表示されること" do
        create(:journal_entry, client: client)
        get journal_entries_path(client_code: client.code)

        expect(response).to have_http_status(:ok)
        body = response.body

        expected_headers = %w[
          No 取引日
          借方勘定科目 借方補助科目 借方部門 借方取引先 借方税区分 借方インボイス 借方金額
          貸方勘定科目 貸方補助科目 貸方部門 貸方取引先 貸方税区分 貸方インボイス 貸方金額
          摘要 タグ メモ カード利用者 ステータス
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
    end
  end
end
