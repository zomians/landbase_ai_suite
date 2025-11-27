# 在庫管理用のカスタムルートを追加
Spree::Core::Engine.routes.append do
  namespace :admin do
    resources :products, only: [] do
      member do
        get 'stock', to: 'stock_items#index'
      end
      resources :stock_items, only: [:edit, :update]
    end
    
    # 在庫アイテム単体での更新（モーダルからのAJAX用）
    resources :stock_items, only: [:update]
  end
end
