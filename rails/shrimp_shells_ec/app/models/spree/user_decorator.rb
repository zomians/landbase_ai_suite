# frozen_string_literal: true

module Spree
  module UserDecorator
    def self.prepended(base)
      # 顧客ランクの定数
      base.const_set(:CUSTOMER_RANKS, {
        bronze: 'ブロンズ',
        silver: 'シルバー',
        gold: 'ゴールド',
        platinum: 'プラチナ'
      }.freeze)

      # 性別の定数
      base.const_set(:GENDERS, {
        male: '男性',
        female: '女性',
        other: 'その他',
        not_specified: '未指定'
      }.freeze)

      # バリデーション
      base.validates :customer_rank, inclusion: { in: base::CUSTOMER_RANKS.keys.map(&:to_s), allow_blank: true }
      base.validates :gender, inclusion: { in: base::GENDERS.keys.map(&:to_s), allow_blank: true }
      base.validates :total_purchase_amount, numericality: { greater_than_or_equal_to: 0 }
      base.validates :total_purchase_count, numericality: { greater_than_or_equal_to: 0 }

      # コールバック
      base.after_update :update_customer_rank, if: -> { saved_change_to_total_purchase_amount? }

      # スコープ
      base.scope :bronze_customers, -> { where(customer_rank: 'bronze') }
      base.scope :silver_customers, -> { where(customer_rank: 'silver') }
      base.scope :gold_customers, -> { where(customer_rank: 'gold') }
      base.scope :platinum_customers, -> { where(customer_rank: 'platinum') }
      base.scope :vip_customers, -> { where(vip_flag: true) }
      base.scope :attention_customers, -> { where(attention_flag: true) }
      base.scope :dm_allowed_customers, -> { where(dm_allowed: true) }
      base.scope :newsletter_subscribers, -> { where(newsletter_subscribed: true) }
      base.scope :recent_purchasers, ->(days = 30) { where('last_purchase_date >= ?', days.days.ago) }
      base.scope :inactive_customers, ->(days = 90) { where('last_purchase_date < ?', days.days.ago).where.not(last_purchase_date: nil) }
      base.scope :by_rank, ->(rank) { where(customer_rank: rank.to_s) }
      base.scope :high_value_customers, -> { where('total_purchase_amount >= ?', 100000) }
    end

    # 顧客ランク名を取得
    def customer_rank_name
      self.class::CUSTOMER_RANKS[customer_rank&.to_sym] || customer_rank
    end

    # 性別名を取得
    def gender_name
      self.class::GENDERS[gender&.to_sym] || '未指定'
    end

    # 顧客ステータスバッジ
    def status_badge
      return '⭐️ VIP' if vip_flag?
      return '⚠️ 要注意' if attention_flag?
      return '🏆 プラチナ' if customer_rank == 'platinum'
      return '🥇 ゴールド' if customer_rank == 'gold'
      return '🥈 シルバー' if customer_rank == 'silver'
      '🥉 ブロンズ'
    end

    # 平均購入金額
    def average_purchase_amount
      return 0 if total_purchase_count.zero?
      (total_purchase_amount / total_purchase_count).round(2)
    end

    # 最終購入からの経過日数
    def days_since_last_purchase
      return nil unless last_purchase_date
      (Date.today - last_purchase_date).to_i
    end

    # 休眠顧客かどうか (90日以上購入なし)
    def dormant?
      return false unless last_purchase_date
      days_since_last_purchase > 90
    end

    # アクティブ顧客かどうか (30日以内に購入)
    def active?
      return false unless last_purchase_date
      days_since_last_purchase <= 30
    end

    # 年齢を計算
    def age
      return nil unless birth_date
      today = Date.today
      age = today.year - birth_date.year
      age -= 1 if today < birth_date + age.years
      age
    end

    # 年代を取得
    def age_group
      return nil unless age
      case age
      when 0..19 then '10代以下'
      when 20..29 then '20代'
      when 30..39 then '30代'
      when 40..49 then '40代'
      when 50..59 then '50代'
      when 60..69 then '60代'
      else '70代以上'
      end
    end

    # フルネームを取得 (addressから)
    def full_name
      return company_name if company_name.present?
      bill_address&.name || ship_address&.name || email
    end

    # 購入履歴を更新
    def update_purchase_stats!(order)
      self.total_purchase_count += 1
      self.total_purchase_amount += order.total
      self.last_purchase_date = Date.today
      save!
    end

    # 顧客ランクを判定して更新
    def calculate_rank
      amount = total_purchase_amount.to_f
      return 'platinum' if amount >= 500000
      return 'gold' if amount >= 200000
      return 'silver' if amount >= 50000
      'bronze'
    end

    # LTV (顧客生涯価値) を計算
    def lifetime_value
      total_purchase_amount.to_f
    end

    # 次回ランクアップまでの金額
    def amount_to_next_rank
      current_amount = total_purchase_amount.to_f
      case customer_rank
      when 'bronze'
        50000 - current_amount
      when 'silver'
        200000 - current_amount
      when 'gold'
        500000 - current_amount
      else
        0
      end
    end

    # マーケティング可能かチェック
    def marketable?
      dm_allowed? && !attention_flag? && !deleted_at
    end

    # メルマガ送信可能かチェック
    def newsletter_sendable?
      newsletter_subscribed? && marketable?
    end

    private

    def update_customer_rank
      new_rank = calculate_rank
      update_column(:customer_rank, new_rank) if customer_rank != new_rank
    end
  end
end

Spree::User.prepend(Spree::UserDecorator)
