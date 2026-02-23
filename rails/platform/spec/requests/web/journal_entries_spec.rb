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
