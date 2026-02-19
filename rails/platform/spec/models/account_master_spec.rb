require "rails_helper"

RSpec.describe AccountMaster, type: :model do
  describe "バリデーション" do
    subject { build(:account_master) }

    describe "必須カラム" do
      it "有効なファクトリが正常に動作する" do
        expect(subject).to be_valid
      end

      it "client_codeが空の場合無効" do
        subject.client_code = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:client_code]).to be_present
      end

      it "account_categoryが空の場合無効" do
        subject.account_category = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:account_category]).to be_present
      end
    end

    describe "confidence_score" do
      it "0は有効" do
        subject.confidence_score = 0
        expect(subject).to be_valid
      end

      it "100は有効" do
        subject.confidence_score = 100
        expect(subject).to be_valid
      end

      it "nilは有効" do
        subject.confidence_score = nil
        expect(subject).to be_valid
      end

      it "負の値は無効" do
        subject.confidence_score = -1
        expect(subject).not_to be_valid
        expect(subject.errors[:confidence_score]).to be_present
      end

      it "101以上は無効" do
        subject.confidence_score = 101
        expect(subject).not_to be_valid
        expect(subject.errors[:confidence_score]).to be_present
      end
    end
  end

  describe "スコープ" do
    describe ".for_client" do
      it "指定クライアントのマスターのみ取得する" do
        master_a = create(:account_master, client_code: "client_a")
        create(:account_master, client_code: "client_b")

        result = described_class.for_client("client_a")
        expect(result).to contain_exactly(master_a)
      end
    end
  end

  describe "キーワードマッチング" do
    before do
      @high = create(:account_master,
                     client_code: "test_client",
                     merchant_keyword: "タクシー東京",
                     description_keyword: "タクシー代",
                     account_category: "旅費交通費",
                     confidence_score: 90)
      @low = create(:account_master,
                    client_code: "test_client",
                    merchant_keyword: "タクシー大阪",
                    description_keyword: "タクシー利用",
                    account_category: "旅費交通費",
                    confidence_score: 60)
      @other_client = create(:account_master,
                             client_code: "other_client",
                             merchant_keyword: "タクシー福岡",
                             description_keyword: "タクシー",
                             account_category: "旅費交通費",
                             confidence_score: 95)
    end

    describe ".find_by_merchant" do
      it "キーワードにマッチする最もconfidence_scoreが高いレコードを1件返す" do
        result = described_class.find_by_merchant("タクシー", client_code: "test_client")
        expect(result).to eq(@high)
      end

      it "マッチしない場合nilを返す" do
        result = described_class.find_by_merchant("存在しない", client_code: "test_client")
        expect(result).to be_nil
      end

      it "単数を返す" do
        result = described_class.find_by_merchant("タクシー", client_code: "test_client")
        expect(result).to be_a(AccountMaster)
      end
    end

    describe ".search_by_merchant" do
      it "キーワードにマッチするレコードをconfidence_score降順で複数返す" do
        result = described_class.search_by_merchant("タクシー", client_code: "test_client")
        expect(result).to eq([@high, @low])
      end

      it "他クライアントのレコードは含まない" do
        result = described_class.search_by_merchant("タクシー", client_code: "test_client")
        expect(result).not_to include(@other_client)
      end

      it "ActiveRecord::Relationを返す" do
        result = described_class.search_by_merchant("タクシー", client_code: "test_client")
        expect(result).to be_a(ActiveRecord::Relation)
      end
    end

    describe ".find_by_description" do
      it "キーワードにマッチする最もconfidence_scoreが高いレコードを1件返す" do
        result = described_class.find_by_description("タクシー", client_code: "test_client")
        expect(result).to eq(@high)
      end

      it "マッチしない場合nilを返す" do
        result = described_class.find_by_description("存在しない", client_code: "test_client")
        expect(result).to be_nil
      end

      it "単数を返す" do
        result = described_class.find_by_description("タクシー", client_code: "test_client")
        expect(result).to be_a(AccountMaster)
      end
    end

    describe ".search_by_description" do
      it "キーワードにマッチするレコードをconfidence_score降順で複数返す" do
        result = described_class.search_by_description("タクシー", client_code: "test_client")
        expect(result).to eq([@high, @low])
      end

      it "他クライアントのレコードは含まない" do
        result = described_class.search_by_description("タクシー", client_code: "test_client")
        expect(result).not_to include(@other_client)
      end

      it "ActiveRecord::Relationを返す" do
        result = described_class.search_by_description("タクシー", client_code: "test_client")
        expect(result).to be_a(ActiveRecord::Relation)
      end
    end

    describe "confidence_scoreソート順" do
      it "search_by_merchantはconfidence_score降順でソートされる" do
        result = described_class.search_by_merchant("タクシー", client_code: "test_client")
        scores = result.pluck(:confidence_score)
        expect(scores).to eq(scores.sort.reverse)
      end

      it "search_by_descriptionはconfidence_score降順でソートされる" do
        result = described_class.search_by_description("タクシー", client_code: "test_client")
        scores = result.pluck(:confidence_score)
        expect(scores).to eq(scores.sort.reverse)
      end
    end
  end

  describe "マルチテナント分離" do
    it "異なるクライアントのデータが混在しない" do
      create(:account_master, client_code: "client_a", account_category: "旅費交通費")
      create(:account_master, client_code: "client_b", account_category: "通信費")

      client_a_masters = described_class.for_client("client_a")
      client_b_masters = described_class.for_client("client_b")

      expect(client_a_masters.count).to eq(1)
      expect(client_b_masters.count).to eq(1)
      expect(client_a_masters.first.account_category).to eq("旅費交通費")
      expect(client_b_masters.first.account_category).to eq("通信費")
    end
  end
end
