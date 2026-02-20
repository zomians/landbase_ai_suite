require "ostruct"

class CleaningManualGeneratorService
  MAX_IMAGES_PER_BATCH = 20
  DEFAULT_MODEL = "claude-sonnet-4-20250514"

  SYSTEM_PROMPT = <<~PROMPT
    あなたは宿泊施設の清掃マニュアル作成の専門家です。
    室内完成画像を分析し、プロの清掃スタッフ向けの詳細な清掃マニュアルを構造化JSONで生成してください。

    ## エリア分類
    画像を以下のカテゴリに分類してください:
    - 寝室: ベッド、布団、枕、ナイトテーブル
    - バスルーム: 浴槽、シャワー、洗面台、鏡
    - トイレ: 便器、トイレットペーパー
    - キッチン: シンク、コンロ、冷蔵庫、調理台
    - リビング・ダイニング: ソファ、テーブル、テレビ、椅子
    - 玄関・廊下: 玄関ドア、靴箱、傘立て
    - バルコニー・テラス: 手すり、物干し、外部家具
    - 洗面所・脱衣所: 洗面台、洗濯機、脱衣かご
    - 和室: 畳、押し入れ、障子、床の間
    - クローゼット・収納: ハンガー、棚、引き出し

    ## 清掃手順の生成ルール
    1. 順序: 上から下、奥から手前の原則に従う
    2. 具体性:「きれいにする」ではなく「乾いたマイクロファイバークロスで拭き上げる」のように具体的に記述
    3. チェックポイント: 各手順の完了基準を明確に定義する
    4. 所要時間: 1人作業を前提に現実的な時間を見積もる（分単位、整数値）

    ## 出力形式
    以下のJSON形式で出力してください。JSON以外のテキストは含めないでください。

    ```json
    {
      "property_name": "施設名",
      "room_type": "部屋タイプ",
      "generated_at": "ISO 8601形式の日時",
      "areas": [
        {
          "area_name": "エリア名",
          "reference_images": ["画像の説明"],
          "cleaning_steps": [
            {
              "order": 1,
              "task": "作業名",
              "description": "具体的な作業内容と方法",
              "checkpoint": "完了基準",
              "estimated_minutes": 5
            }
          ],
          "quality_standards": ["品質基準"]
        }
      ],
      "supplies_needed": ["必要な備品・消耗品"],
      "total_estimated_minutes": 45
    }
    ```
  PROMPT

  def initialize(images:, property_name:, room_type:, labels: [])
    @images = images
    @property_name = property_name
    @room_type = room_type
    @labels = labels
  end

  def call
    batches = @images.each_slice(MAX_IMAGES_PER_BATCH).to_a

    if batches.size == 1
      result = generate_for_batch(batches.first)
      return result unless result.success?
      OpenStruct.new(success?: true, data: result.data)
    else
      merged = merge_batch_results(batches)
      return merged unless merged.success?
      OpenStruct.new(success?: true, data: merged.data)
    end
  rescue Anthropic::Errors::APIError => e
    OpenStruct.new(success?: false, data: {}, error: "Anthropic API エラー: #{e.message}")
  rescue JSON::ParserError => e
    OpenStruct.new(success?: false, data: {}, error: "JSON パースエラー: #{e.message}")
  rescue StandardError => e
    OpenStruct.new(success?: false, data: {}, error: "予期しないエラー: #{e.message}")
  end

  private

  def generate_for_batch(image_batch)
    content = build_content(image_batch)
    response = client.messages.create(
      model: ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL),
      max_tokens: 8192,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: content }]
    )

    text_block = response.content.find { |c| c.respond_to?(:type) && c.type.to_s == "text" }
    text = text_block&.respond_to?(:text) ? text_block.text : text_block.to_s
    raise JSON::ParserError, "APIからテキスト応答がありませんでした" if text.blank?

    json_str = extract_json(text)
    data = JSON.parse(json_str, symbolize_names: true)

    data[:property_name] = @property_name
    data[:room_type] = @room_type
    data[:generated_at] = Time.current.iso8601

    OpenStruct.new(success?: true, data: data)
  end

  def merge_batch_results(batches)
    all_areas = []
    all_supplies = []

    batches.each do |batch|
      result = generate_for_batch(batch)
      return result unless result.success?

      all_areas.concat(result.data[:areas] || [])
      all_supplies.concat(result.data[:supplies_needed] || [])
    end

    total_minutes = all_areas.sum { |a| a[:cleaning_steps]&.sum { |s| s[:estimated_minutes].to_i } || 0 }

    data = {
      property_name: @property_name,
      room_type: @room_type,
      generated_at: Time.current.iso8601,
      areas: all_areas,
      supplies_needed: all_supplies.uniq,
      total_estimated_minutes: total_minutes
    }

    OpenStruct.new(success?: true, data: data)
  end

  def build_content(image_batch)
    content = []

    image_batch.each_with_index do |image, i|
      image_data = Base64.strict_encode64(image.read)
      image.rewind
      media_type = image.content_type

      content << {
        type: "image",
        source: {
          type: "base64",
          media_type: media_type,
          data: image_data
        }
      }

      label = @labels[i]
      content << { type: "text", text: "画像#{i + 1}: #{label}" } if label.present?
    end

    content << {
      type: "text",
      text: "上記の室内完成画像を分析し、「#{@property_name}」の「#{@room_type}」タイプの部屋の清掃マニュアルを生成してください。JSONのみで出力してください。"
    }

    content
  end

  def extract_json(text)
    if text =~ /```(?:json)?\s*\n?(.*?)\n?```/m
      $1.strip
    else
      text.strip
    end
  end

  def client
    @client ||= Anthropic::Client.new
  end
end
