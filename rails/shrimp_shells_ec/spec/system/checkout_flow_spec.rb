# frozen_string_literal: true

require 'solidus_starter_frontend_spec_helper'

RSpec.describe 'Checkout Flow', type: :system do
  let!(:store) { create(:store) }
  let!(:product) do
    create(:product, name: "Test Product", price: 10.00).tap do |product|
      product.master.stock_items.update_all count_on_hand: 10
    end
  end
  let(:user) { create(:user) }

  before do
    visit products_path
    click_link 'Test Product'
    click_button 'add-to-cart-button'
  end

  describe 'Cart page with delivery information' do
    it 'displays delivery information form' do
      visit cart_path
      
      expect(page).to have_content I18n.t('spree.delivery_information')
      expect(page).to have_field I18n.t('spree.preferred_delivery_date')
      expect(page).to have_select I18n.t('spree.preferred_delivery_time')
      expect(page).to have_select I18n.t('spree.carrier')
      expect(page).to have_field I18n.t('spree.allergies_confirmation')
      expect(page).to have_field I18n.t('spree.delivery_notes')
    end

    it 'validates delivery date is at least 2 days from today' do
      visit cart_path
      
      # 明日の日付を選択（エラーになるはず）
      fill_in I18n.t('spree.preferred_delivery_date'), with: Date.tomorrow.to_s
      check I18n.t('spree.allergies_confirmation')
      
      # チェックアウトボタンをクリック
      within '#checkout-button-form' do
        click_button I18n.t('spree.checkout')
      end
      
      # エラーメッセージが表示されることを確認
      expect(page).to have_content I18n.t('activerecord.errors.models.spree/order.attributes.preferred_delivery_date.must_be_at_least_two_days_from_today')
    end

    it 'updates delivery information successfully' do
      visit cart_path
      
      delivery_date = Date.today + 3.days
      fill_in I18n.t('spree.preferred_delivery_date'), with: delivery_date.to_s
      select Spree::Order::DELIVERY_TIME_SLOTS.first, from: I18n.t('spree.preferred_delivery_time')
      select 'ヤマト運輸', from: I18n.t('spree.carrier')
      check I18n.t('spree.allergies_confirmation')
      fill_in I18n.t('spree.delivery_notes'), with: '不在時は宅配ボックスへ'
      
      within '#delivery-info-form' do
        click_button I18n.t('spree.update_delivery_info')
      end
      
      expect(page).to have_content I18n.t('spree.cart_successfully_updated')
    end

    it 'requires allergy confirmation before checkout' do
      visit cart_path
      
      delivery_date = Date.today + 3.days
      fill_in I18n.t('spree.preferred_delivery_date'), with: delivery_date.to_s
      
      # アレルギー確認チェックボックスをチェックしない
      # チェックアウトボタンが無効化されていることを確認
      checkout_button = find('#checkout-link')
      expect(checkout_button).to be_disabled
    end
  end

  describe 'Checkout process' do
    before do
      visit cart_path
      
      # 配送情報を入力
      delivery_date = Date.today + 3.days
      fill_in I18n.t('spree.preferred_delivery_date'), with: delivery_date.to_s
      select Spree::Order::DELIVERY_TIME_SLOTS.first, from: I18n.t('spree.preferred_delivery_time')
      select 'ヤマト運輸', from: I18n.t('spree.carrier')
      check I18n.t('spree.allergies_confirmation')
      
      within '#checkout-button-form' do
        click_button I18n.t('spree.checkout')
      end
    end

    it 'displays delivery information in checkout summary' do
      expect(page).to have_content I18n.t('spree.delivery_information')
      expect(page).to have_content I18n.t('spree.preferred_delivery_date')
      expect(page).to have_content 'ヤマト運輸'
    end

    it 'completes checkout and shows order confirmation' do
      # アドレスステップ
      fill_in 'order_bill_address_attributes_firstname', with: 'John'
      fill_in 'order_bill_address_attributes_lastname', with: 'Doe'
      fill_in 'order_bill_address_attributes_address1', with: '123 Main St'
      fill_in 'order_bill_address_attributes_city', with: 'Tokyo'
      fill_in 'order_bill_address_attributes_zipcode', with: '123-4567'
      fill_in 'order_bill_address_attributes_phone', with: '090-1234-5678'
      click_button I18n.t('spree.save_and_continue')
      
      # 配送ステップ
      click_button I18n.t('spree.save_and_continue')
      
      # 支払いステップ（銀行振込を選択）
      choose I18n.t('spree.bank_transfer')
      click_button I18n.t('spree.save_and_continue')
      
      # 確認ステップ
      click_button I18n.t('spree.complete_order')
      
      # 注文完了ページ
      expect(page).to have_content I18n.t('spree.thank_you_for_your_order')
      expect(page).to have_content I18n.t('spree.order_number')
      expect(page).to have_content I18n.t('spree.delivery_schedule')
      expect(page).to have_content I18n.t('spree.carrier')
    end
  end

  describe 'Order completion page' do
    let(:order) do
      create(:completed_order_with_totals,
        line_items_count: 1,
        preferred_delivery_date: Date.today + 3.days,
        preferred_delivery_time: Spree::Order::DELIVERY_TIME_SLOTS.first,
        carrier_code: :yamato,
        allergies_confirmed: true
      )
    end

    before do
      allow_any_instance_of(OrdersController).to receive(:try_spree_current_user).and_return(order.user)
      visit order_path(order)
    end

    it 'displays order details with delivery information' do
      expect(page).to have_content order.number
      expect(page).to have_content I18n.t('spree.delivery_schedule')
      expect(page).to have_content I18n.l(order.preferred_delivery_date, format: :long)
      expect(page).to have_content order.preferred_delivery_time
      expect(page).to have_content order.carrier_name
      expect(page).to have_content I18n.t('spree.contact_info')
    end
  end
end
