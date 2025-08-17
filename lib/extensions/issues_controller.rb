# frozen_string_literal: true

module Extensions
  module IssuesController
    extend ActiveSupport::Concern

    # 注意：我們不使用控制器擴展，而是依賴模型驗證
    # 這樣可以確保在正確的時機進行資料保護檢查
    # 並且不會干擾正常的控制器流程
  end
end
