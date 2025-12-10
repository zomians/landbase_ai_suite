# frozen_string_literal: true

require 'solidus_starter_frontend_spec_helper'

RSpec.describe Spree::Order, type: :model do
  describe 'validations' do
    context 'on checkout' do
      let(:order) { create(:order_ready_to_ship, state: 'delivery') }

      it 'requires allergies_confirmed' do
        order.allergies_confirmed = false
        expect(order).not_to be_valid(:checkout)
        expect(order.errors[:allergies_confirmed]).to include I18n.t('activerecord.errors.models.spree/order.attributes.allergies_confirmed.must_be_accepted')
      end

      it 'requires preferred_delivery_date' do
        order.preferred_delivery_date = nil
        expect(order).not_to be_valid(:checkout)
        expect(order.errors[:preferred_delivery_date]).to include I18n.t('activerecord.errors.models.spree/order.attributes.preferred_delivery_date.required_for_checkout')
      end

      it 'validates delivery date is at least 2 days from today' do
        order.preferred_delivery_date = Date.tomorrow
        expect(order).not_to be_valid
        expect(order.errors[:preferred_delivery_date]).to include I18n.t('activerecord.errors.models.spree/order.attributes.preferred_delivery_date.must_be_at_least_two_days_from_today')
      end

      it 'accepts valid delivery date' do
        order.preferred_delivery_date = Date.today + 3.days
        order.allergies_confirmed = true
        expect(order).to be_valid(:checkout)
      end
    end
  end

  describe '#carrier_name' do
    let(:order) { build(:order) }

    it 'returns Japanese carrier name for yamato' do
      order.carrier_code = 'yamato'
      expect(order.carrier_name).to eq 'ヤマト運輸'
    end

    it 'returns Japanese carrier name for sagawa' do
      order.carrier_code = 'sagawa'
      expect(order.carrier_name).to eq '佐川急便'
    end

    it 'returns the carrier_code if not found in CARRIER_CODES' do
      order.carrier_code = 'unknown'
      expect(order.carrier_name).to eq 'unknown'
    end
  end

  describe '#delivery_date_valid?' do
    let(:order) { build(:order) }

    it 'returns true when delivery date is nil' do
      order.preferred_delivery_date = nil
      expect(order.delivery_date_valid?).to be true
    end

    it 'returns false when delivery date is tomorrow' do
      order.preferred_delivery_date = Date.tomorrow
      expect(order.delivery_date_valid?).to be false
    end

    it 'returns true when delivery date is 2 days from today' do
      order.preferred_delivery_date = Date.today + 2.days
      expect(order.delivery_date_valid?).to be true
    end

    it 'returns true when delivery date is 3+ days from today' do
      order.preferred_delivery_date = Date.today + 5.days
      expect(order.delivery_date_valid?).to be true
    end
  end

  describe '#days_until_delivery' do
    let(:order) { build(:order) }

    it 'returns nil when preferred_delivery_date is nil' do
      order.preferred_delivery_date = nil
      expect(order.days_until_delivery).to be_nil
    end

    it 'returns correct number of days' do
      order.preferred_delivery_date = Date.today + 5.days
      expect(order.days_until_delivery).to eq 5
    end
  end
end
