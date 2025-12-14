# frozen_string_literal: true

class UserAddressesController < StoreController
  before_action :authenticate_spree_user!
  before_action :load_user
  before_action :set_address, only: [:edit, :update, :destroy]

  def index
    # ユーザーの配送先と請求先を表示
    @addresses = []
    @addresses << @user.ship_address if @user.ship_address
    @addresses << @user.bill_address if @user.bill_address && @user.bill_address != @user.ship_address
    
    # 過去の注文から住所を取得
    order_addresses = @user.orders.complete.includes(:ship_address, :bill_address)
                           .flat_map { |o| [o.ship_address, o.bill_address] }
                           .compact
                           .uniq
                           .reject { |addr| @addresses.map(&:id).include?(addr.id) }
    
    @addresses += order_addresses
    @addresses.compact!
    @addresses.uniq!(&:id)
  end

  def new
    @address = Spree::Address.new(country: Spree::Country.find_by(iso: 'JP'))
  end

  def create
    @address = Spree::Address.new(address_params)

    if @address.save
      # 常に新しい住所をデフォルトとして設定
      @user.update(ship_address: @address)
      
      # 請求先が未設定の場合のみ設定
      if @user.bill_address.nil?
        @user.update(bill_address: @address)
      end

      redirect_to user_addresses_path, notice: '住所を追加しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @address.update(address_params)
      redirect_to user_addresses_path, notice: '住所を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # デフォルト配送先の場合は削除不可
    if @user.ship_address_id == @address.id || @user.bill_address_id == @address.id
      redirect_to user_addresses_path, alert: 'デフォルトの住所は削除できません'
      return
    end

    @address.destroy
    redirect_to user_addresses_path, notice: '住所を削除しました'
  end

  private

  def load_user
    @user = spree_current_user
  end

  def set_address
    @address = Spree::Address.find(params[:id])
    
    # このユーザーの住所かチェック
    unless [@user.ship_address_id, @user.bill_address_id].include?(@address.id) ||
           @user.orders.complete.any? { |o| [o.ship_address_id, o.bill_address_id].include?(@address.id) }
      redirect_to user_addresses_path, alert: 'この住所にアクセスする権限がありません'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to user_addresses_path, alert: '住所が見つかりません'
  end

  def address_params
    params.require(:address).permit(
      :name, :company, :address1, :address2,
      :city, :zipcode, :phone, :state_id, :country_id,
      :alternative_phone, :state_name
    )
  end
end
