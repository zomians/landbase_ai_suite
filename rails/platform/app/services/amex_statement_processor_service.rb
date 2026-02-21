class AmexStatementProcessorService
  Result = Data.define(:success, :data, :error) do
    alias_method :success?, :success
  end

  SYSTEM_PROMPT = <<~PROMPT
    あなたは日本の経理・簿記の専門家です。以下のルールに厳密に従い、Amex 利用明細 PDF から抽出した取引データを仕訳台帳データに変換してください。

    ### 前提知識

    - **複式簿記**: すべての取引は借方・貸方の両方に同額を記録する
    - **貸方は全取引共通**: 勘定科目「未払金」、補助科目「アメックス」
    - **借方の勘定科目**: 取引内容から推定する（後述のマッピングルール参照）

    ### 勘定科目推定ルール

    取引の店舗名・利用先から、以下の優先順位で借方勘定科目を推定する。

    #### 優先度1: 店舗名キーワードでの一致（高精度）

    | キーワード | 借方勘定科目 | 備考 |
    |---|---|---|
    | Amazon, アマゾン | 消耗品費 | 書籍の場合は「新聞図書費」 |
    | ENEOS, 出光, コスモ, Shell, エネオス, IDEMITSU | 車両費 | ガソリンスタンド |
    | UBER EATS, Uber Eats, ウーバーイーツ | 会議費 | 軽減税率8%対象 |
    | 出前館 | 会議費 | 軽減税率8%対象 |
    | Adobe, ADOBE | 通信費 | SaaS/サブスクリプション |
    | Google, GOOGLE | 通信費 | クラウドサービス |
    | Microsoft, MICROSOFT | 通信費 | SaaS/サブスクリプション |
    | AWS, Amazon Web Services | 通信費 | クラウドサービス |
    | Zoom, ZOOM | 通信費 | SaaS/サブスクリプション |
    | Slack, SLACK | 通信費 | SaaS/サブスクリプション |
    | ChatGPT, OpenAI, OPENAI | 通信費 | SaaS/サブスクリプション |
    | Anthropic, ANTHROPIC | 通信費 | SaaS/サブスクリプション |
    | セブンイレブン, セブン-イレブン, 7-ELEVEN | 消耗品費 | 軽減税率8%対象（食品の場合） |
    | ローソン, LAWSON | 消耗品費 | 軽減税率8%対象（食品の場合） |
    | ファミリーマート, FamilyMart, ファミマ | 消耗品費 | 軽減税率8%対象（食品の場合） |
    | ミニストップ, MINISTOP | 消耗品費 | 軽減税率8%対象（食品の場合） |
    | イオン, AEON | 消耗品費 | 軽減税率8%対象（食品の場合） |
    | 西友, SEIYU | 消耗品費 | 軽減税率8%対象（食品の場合） |
    | スターバックス, STARBUCKS | 会議費 | |
    | タリーズ, TULLY'S | 会議費 | |
    | ドトール, DOUTOR | 会議費 | |
    | JR, ＪＲ | 旅費交通費 | |
    | ANA, 全日空 | 旅費交通費 | |
    | JAL, 日本航空 | 旅費交通費 | |
    | タクシー, Taxi | 旅費交通費 | |
    | 駐車場, パーキング, PARKING | 旅費交通費 | |
    | ETC | 旅費交通費 | 高速道路 |
    | ヤマト運輸, 佐川急便, 日本郵便 | 荷造運賃 | 配送料 |
    | 東京電力, 関西電力, 沖縄電力 | 水道光熱費 | |
    | 東京ガス, 大阪ガス | 水道光熱費 | |
    | NTT, ソフトバンク, KDDI, au, docomo | 通信費 | 通信料 |

    #### 優先度2: 取引内容・カテゴリからの推定（中精度）

    | 取引内容キーワード | 借方勘定科目 |
    |---|---|
    | 駐車場, パーキング | 旅費交通費 |
    | 高速, 有料道路 | 旅費交通費 |
    | 宿泊, ホテル, Hotel | 旅費交通費 |
    | レンタカー | 車両費 |
    | 保険 | 保険料 |
    | 修繕, 修理, メンテナンス | 修繕費 |

    #### 優先度3: AI 推論（低精度）

    上記ルールでマッチしない場合は、店舗名・取引内容から最も適切な勘定科目を推論する。ただし、推論に自信がない場合は `status` を `"review_required"` に設定し、`memo` に推論理由を記載する。

    ### 消費税率判定ルール

    #### 標準税率: 10%（デフォルト）
    - `debit_tax_category`: `"課税仕入10%（非インボイス）"`
    - ほとんどの取引はこちらに該当
    - クレカ明細にはインボイス番号が記載されないため、デフォルトは「非インボイス」とする

    #### 軽減税率: 8%
    - `debit_tax_category`: `"課税仕入8%（軽減・非インボイス）"`
    - コンビニ（食品購入）、スーパー（食品購入）、フードデリバリー（Uber Eats、出前館）

    #### 対象外（海外取引）
    - `debit_tax_category`: `"対象外"`
    - 海外での物品購入・飲食など、日本の消費税が課税されない取引
    - 判定方法: 外貨建て金額（USD等）の記載がある取引、または明らかに海外店舗での利用

    #### 課対仕入（リバースチャージ）（海外SaaS）
    - `debit_tax_category`: `"課対仕入（リバースチャージ）"`
    - 国外事業者からの電気通信利用役務の提供（SaaS・クラウドサービス等）
    - `memo` に「国外事業者からの役務提供」と記載する
    - 対象: OpenAI, Perplexity, GENSPARK.AI, VREW, SHENGSHU AI, n8n CLOUD (PADDLE.NET), PLAUD.AI, 2SHORTAI (LEMSQZY) 等

    #### その他注意事項
    - コンビニ・スーパーは食品購入が主と推定し軽減税率8%を適用
    - 飲食店でのイートインは標準税率10%、テイクアウト・デリバリーは軽減税率8%
    - 海外のコンビニ・飲食チェーンでも外貨建ての場合は「対象外」
    - 判断が困難な場合は標準税率10%（非インボイス）を適用し、`memo` に「税率要確認」と記載

    ### 処理上の注意事項

    1. **金額の扱い**: PDF に記載された税込金額をそのまま使用する。借方金額と貸方金額は必ず一致させる
    2. **日付の扱い**: PDF の日付を YYYY-MM-DD 形式に変換する。年が省略されている場合は明細期間から推定する
    3. **店舗名の正規化**: PDF に記載された店舗名をそのまま `debit_partner` に設定する
    4. **返品・キャンセル（逆仕訳）**: 返品・返金・調整によるマイナス金額の取引は、借方と貸方を逆にして正の金額で記録する（逆仕訳）。`memo` に「返品・調整（逆仕訳）」と記載する
    5. **外貨取引**: 円換算後の金額を使用する。外貨情報は `memo` に記載する
    6. **複数ページ**: PDF が複数ページの場合、全ページの取引を連番で通しナンバリングする
    7. **年会費・手数料**: Amex の年会費・手数料は「支払手数料」として処理する
    8. **複数カード会員**: 法人カードの場合、各会員セクションのヘッダーから会員名を読み取り、`cardholder` に記録する

    ### 出力 JSON 仕様

    以下の構造で JSON を出力してください。JSON以外のテキストは含めないでください。

    ```json
    {
      "statement_period": "YYYY年M月",
      "card_type": "アメリカン・エキスプレス",
      "generated_at": "ISO 8601 形式（JST）",
      "transactions": [
        {
          "transaction_no": 1,
          "date": "YYYY-MM-DD",
          "debit_account": "勘定科目名",
          "debit_sub_account": "",
          "debit_department": "",
          "debit_partner": "店舗名",
          "debit_tax_category": "課税仕入10%（非インボイス）",
          "debit_invoice": "",
          "debit_amount": 0,
          "credit_account": "未払金",
          "credit_sub_account": "アメックス",
          "credit_department": "",
          "credit_partner": "",
          "credit_tax_category": "",
          "credit_invoice": "",
          "credit_amount": 0,
          "description": "店舗名 利用内容",
          "tag": "amex",
          "memo": "",
          "cardholder": "カード会員名",
          "status": "ok"
        }
      ],
      "summary": {
        "total_transactions": 0,
        "total_amount": 0,
        "review_required_count": 0,
        "accounts_breakdown": {}
      }
    }
    ```
  PROMPT

  def initialize(pdf:, client_code:)
    @pdf = pdf
    @client_code = client_code
  end

  def call
    unless ENV["ANTHROPIC_API_KEY"].present?
      return Result.new(success: false, data: {}, error: "ANTHROPIC_API_KEY が設定されていません")
    end

    pdf_data = read_pdf
    account_master_context = build_account_master_context
    user_prompt = build_user_prompt(account_master_context)

    response = client.messages.create(
      model: ENV.fetch("ANTHROPIC_MODEL", "claude-sonnet-4-6"),
      max_tokens: 16384,
      system: SYSTEM_PROMPT,
      messages: [{
        role: "user",
        content: [
          {
            type: "document",
            source: {
              type: "base64",
              media_type: "application/pdf",
              data: pdf_data
            }
          },
          {
            type: "text",
            text: user_prompt
          }
        ]
      }]
    )

    text_block = response.content.find { |c| c.respond_to?(:type) && c.type.to_s == "text" }
    text = text_block&.respond_to?(:text) ? text_block.text : text_block.to_s
    raise JSON::ParserError, "APIからテキスト応答がありませんでした" if text.blank?

    json_str = extract_json(text)
    data = JSON.parse(json_str, symbolize_names: true)

    Result.new(success: true, data: data, error: nil)
  rescue Anthropic::Errors::APIError => e
    Result.new(success: false, data: {}, error: "Anthropic API エラー: #{e.message}")
  rescue JSON::ParserError => e
    Result.new(success: false, data: {}, error: "JSON パースエラー: #{e.message}")
  rescue StandardError => e
    Result.new(success: false, data: {}, error: "予期しないエラー: #{e.message}")
  end

  private

  def read_pdf
    if @pdf.respond_to?(:download)
      Base64.strict_encode64(@pdf.download)
    elsif @pdf.respond_to?(:read)
      @pdf.rewind if @pdf.respond_to?(:rewind)
      Base64.strict_encode64(@pdf.read)
    else
      Base64.strict_encode64(File.binread(@pdf.to_s))
    end
  end

  def build_account_master_context
    masters = AccountMaster.for_client(@client_code).for_source("amex").order(confidence_score: :desc)
    return "" if masters.empty?

    lines = masters.map do |m|
      parts = []
      parts << "店舗名キーワード: #{m.merchant_keyword}" if m.merchant_keyword.present?
      parts << "取引内容キーワード: #{m.description_keyword}" if m.description_keyword.present?
      parts << "→ 勘定科目: #{m.account_category}"
      parts << "(信頼度: #{m.confidence_score}%)" if m.confidence_score
      parts.join(" / ")
    end

    <<~CONTEXT

      ### 優先度0: 確定マッチング（AccountMasterデータベース）

      以下はクライアント固有の勘定科目マッピングです。これらは最優先で適用してください。

      #{lines.join("\n")}
    CONTEXT
  end

  def build_user_prompt(account_master_context)
    prompt = "添付のAmex利用明細PDFを読み取り、全取引を仕訳台帳データに変換してください。JSONのみで出力してください。"
    prompt += account_master_context if account_master_context.present?
    prompt
  end

  def extract_json(text)
    if text =~ /```(?:json)?\s*\n?(.*?)\n?```/m
      $1.strip
    else
      text.strip
    end
  end

  def client
    @client ||= Anthropic::Client.new(timeout: 180.0)
  end
end
