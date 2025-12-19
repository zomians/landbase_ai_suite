# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Shipment, type: :model do
  include FactoryBot::Syntax::Methods
  describe '定数' do
    it 'CARRIER_CODESが定義されている' do
      expect(described_class::CARRIER_CODES).to be_a(Hash)
      expect(described_class::CARRIER_CODES[:yamato]).to eq("ヤマト運輸")
    end

    it 'DELIVERY_STATUSESが定義されている' do
      expect(described_class::DELIVERY_STATUSES).to be_a(Hash)
      expect(described_class::DELIVERY_STATUSES[:delivered]).to eq("配達完了")
    end
  end

  describe 'バリデーション' do
    let(:shipment) { create(:shipment) }

    it '有効なcarrier_codeを受け入れる' do
      shipment.carrier_code = 'yamato'
      expect(shipment).to be_valid
    end

    it '無効なcarrier_codeを拒否する' do
      shipment.carrier_code = 'invalid_carrier'
      expect(shipment).not_to be_valid
      expect(shipment.errors[:carrier_code]).to be_present
    end

    it 'delivery_attemptsが0以上であることを検証' do
      shipment.delivery_attempts = -1
      expect(shipment).not_to be_valid
    end

    it '有効なtracking_urlを受け入れる' do
      shipment.tracking_url = 'https://example.com/tracking/123'
      expect(shipment).to be_valid
    end

    it '無効なtracking_urlを拒否する' do
      new_shipment = create(:shipment)
      new_shipment.tracking_url = 'invalid-url-without-protocol'
      expect(new_shipment).not_to be_valid
      expect(new_shipment.errors[:tracking_url]).to be_present
    end

    it '過去の配送予定日を拒否する' do
      shipment.estimated_delivery_date = 1.day.ago.to_date
      expect(shipment).not_to be_valid
      expect(shipment.errors[:estimated_delivery_date]).to include("は過去の日付にできません")
    end
  end

  describe '#carrier_name' do
    let(:shipment) { create(:shipment) }

    it 'carrier_codeから配送業者名を取得' do
      shipment.carrier_code = 'yamato'
      expect(shipment.carrier_name).to eq("ヤマト運輸")
    end

    it 'carrier_codeがnilの場合nilを返す' do
      shipment.carrier_code = nil
      expect(shipment.carrier_name).to be_nil
    end
  end

  describe '#delivery_status_name' do
    let(:shipment) { create(:shipment) }

    it 'delivery_statusから配送ステータス名を取得' do
      shipment.delivery_status = 'delivered'
      expect(shipment.delivery_status_name).to eq("配達完了")
    end
  end

  describe '#mark_as_delivered!' do
    let(:shipment) { create(:shipment, state: 'shipped') }

    it '配達完了状態に更新' do
      shipment.mark_as_delivered!
      expect(shipment.reload.delivery_status).to eq('delivered')
      expect(shipment.delivered_at).to be_present
    end
  end

  describe '#mark_as_failed!' do
    let(:shipment) { create(:shipment, state: 'shipped', delivery_attempts: 0) }

    it '配達失敗を記録' do
      shipment.mark_as_failed!(reason: '不在')
      expect(shipment.reload.delivery_status).to eq('failed')
      expect(shipment.delivery_attempts).to eq(1)
      expect(shipment.delivery_notes).to include('配達失敗: 不在')
    end
  end

  describe '#prepare_redelivery!' do
    let(:shipment) { create(:shipment, state: 'shipped', delivery_status: 'failed', delivery_attempts: 1) }

    it '再配達準備状態に更新' do
      shipment.prepare_redelivery!
      expect(shipment.reload.delivery_status).to be_nil
      expect(shipment.delivery_notes).to include('再配達準備')
    end
  end

  describe '#mark_out_for_delivery!' do
    let(:shipment) { create(:shipment, state: 'shipped') }

    it '配達中状態に更新' do
      shipment.mark_out_for_delivery!
      expect(shipment.reload.delivery_status).to eq('out_for_delivery')
    end
  end

  describe '#generate_tracking_url' do
    it 'ヤマト運輸の追跡URLを生成' do
      shipment = create(:shipment, tracking: '1234567890', carrier_code: 'yamato')
      url = shipment.generate_tracking_url
      expect(url).to include('kuronekoyamato.co.jp')
      expect(url).to include('1234567890')
      expect(shipment.reload.tracking_url).to eq(url)
    end

    it '佐川急便の追跡URLを生成' do
      shipment = create(:shipment, tracking: '1234567890', carrier_code: 'sagawa')
      url = shipment.generate_tracking_url
      expect(url).to include('sagawa-exp.co.jp')
      expect(shipment.reload.tracking_url).to eq(url)
    end

    it '日本郵便の追跡URLを生成' do
      shipment = create(:shipment, tracking: '1234567890', carrier_code: 'japan_post')
      url = shipment.generate_tracking_url
      expect(url).to include('post.japanpost.jp')
      expect(shipment.reload.tracking_url).to eq(url)
    end

    it '西濃運輸の追跡URLを生成' do
      shipment = create(:shipment, tracking: '1234567890', carrier_code: 'seino')
      url = shipment.generate_tracking_url
      expect(url).to include('seino.co.jp')
      expect(shipment.reload.tracking_url).to eq(url)
    end
  end

  describe '#days_until_delivery' do
    let(:shipment) { create(:shipment) }

    it '配送予定日までの日数を計算' do
      shipment.estimated_delivery_date = 3.days.from_now.to_date
      expect(shipment.days_until_delivery).to eq(3)
    end

    it '配送予定日がない場合nilを返す' do
      shipment.estimated_delivery_date = nil
      expect(shipment.days_until_delivery).to be_nil
    end
  end

  describe '#delivery_overdue?' do
    let(:shipment) { create(:shipment) }

    it '配送予定日を過ぎている場合true' do
      shipment.estimated_delivery_date = 1.day.ago.to_date
      shipment.state = 'shipped'
      expect(shipment.delivery_overdue?).to be true
    end

    it '配達完了の場合false' do
      shipment.estimated_delivery_date = 1.day.ago.to_date
      shipment.delivery_status = 'delivered'
      expect(shipment.delivery_overdue?).to be false
    end
  end

  describe '#status_badge' do
    let(:shipment) { create(:shipment) }

    it '各ステータスに応じたバッジを返す' do
      shipment.delivery_status = 'delivered'
      expect(shipment.status_badge).to eq("✅ 配達完了")

      shipment.delivery_status = 'out_for_delivery'
      expect(shipment.status_badge).to eq("🚛 配達中")
      
      shipment.delivery_status = nil
      shipment.state = 'shipped'
      expect(shipment.status_badge).to eq("🚚 配送中")
    end
  end

  describe '#shipping_summary' do
    let(:shipment) do
      create(:shipment,
        carrier_code: 'yamato',
        tracking: '1234567890',
        estimated_delivery_date: 3.days.from_now.to_date,
        delivery_attempts: 1
      )
    end

    it '配送情報のサマリーを返す' do
      summary = shipment.shipping_summary
      expect(summary).to include('ヤマト運輸')
      expect(summary).to include('1234567890')
      expect(summary).to include('再配達: 1回')
    end
  end

  describe 'スコープ' do
    let!(:yamato_shipment) { create(:shipment, carrier_code: 'yamato') }
    let!(:sagawa_shipment) { create(:shipment, carrier_code: 'sagawa') }
    let!(:delivered_shipment) { create(:shipment, state: 'shipped', delivery_status: 'delivered', delivered_at: Time.current, estimated_delivery_date: 1.day.ago.to_date) }
    let!(:overdue_shipment) do
      shipment = create(:shipment, state: 'shipped', estimated_delivery_date: 2.days.from_now.to_date)
      shipment.update_column(:estimated_delivery_date, 1.day.ago.to_date)
      shipment
    end

    it 'by_carrierスコープ' do
      expect(described_class.by_carrier('yamato')).to include(yamato_shipment)
      expect(described_class.by_carrier('yamato')).not_to include(sagawa_shipment)
    end

    it 'deliveredスコープ' do
      expect(described_class.delivered).to include(delivered_shipment)
      expect(described_class.delivered).not_to include(yamato_shipment)
    end

    it 'delivery_overdueスコープ' do
      expect(described_class.delivery_overdue).to include(overdue_shipment)
      expect(described_class.delivery_overdue).not_to include(delivered_shipment)
    end
  end
end
