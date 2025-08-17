// Data Protection Guard Plugin - Form Restoration Loader
// 用於在編輯頁面載入表單恢復功能

$(document).ready(function() {
  // 檢查是否有伺服器端恢復的資料
  if (typeof restoredFormDataJson !== 'undefined' && restoredFormDataJson) {
    console.log('Data Protection Guard: Restoring form data from server');
    restoreServerFormData(restoredFormDataJson);
  }
  
  // 檢查是否有 flash 錯誤訊息（表示有資料保護違規）
  if ($('.flash.error').length > 0) {
    console.log('Data Protection Guard: Flash error detected, attempting form restoration');
    // 嘗試從 localStorage 恢復表單資料
    restoreFormData();
  }
  
  // 在表單提交前保存資料
  $('#issue-form').on('submit', function() {
    console.log('Data Protection Guard: Saving form data before submission');
    saveFormData();
  });
});

function saveFormData() {
  var formData = {};
  
  // 保存 issue 欄位
  $('#issue-form input, #issue-form textarea, #issue-form select').each(function() {
    var $field = $(this);
    var name = $field.attr('name');
    var value = $field.val();
    
    if (name && value !== undefined) {
      formData[name] = value;
    }
  });
  
  // 保存到 localStorage
  localStorage.setItem('data_protection_form_data', JSON.stringify(formData));
  localStorage.setItem('data_protection_form_timestamp', Date.now());
}

function restoreFormData() {
  try {
    var formData = JSON.parse(localStorage.getItem('data_protection_form_data'));
    var timestamp = localStorage.getItem('data_protection_form_timestamp');
    
    // 檢查資料是否在 5 分鐘內保存的
    if (formData && timestamp && (Date.now() - timestamp < 300000)) {
      console.log('Data Protection Guard: Restoring form data from localStorage');
      
      // 恢復表單資料
      Object.keys(formData).forEach(function(fieldName) {
        var $field = $('[name="' + fieldName + '"]');
        if ($field.length > 0) {
          $field.val(formData[fieldName]);
          
          // 觸發 change 事件以更新相關的 UI 元素
          $field.trigger('change');
        }
      });
      
      // 清除保存的資料
      localStorage.removeItem('data_protection_form_data');
      localStorage.removeItem('data_protection_form_timestamp');
      
      // 顯示恢復訊息
      showRestoreMessage();
    }
  } catch (e) {
    console.log('Data Protection Guard: Error restoring form data:', e);
  }
}

function restoreServerFormData(formDataJson) {
  try {
    var formData = JSON.parse(formDataJson);
    console.log('Data Protection Guard: Restoring server form data:', formData);
    
    // 恢復表單資料
    Object.keys(formData).forEach(function(fieldName) {
      var $field = $('[name="' + fieldName + '"]');
      if ($field.length > 0) {
        $field.val(formData[fieldName]);
        
        // 觸發 change 事件以更新相關的 UI 元素
        $field.trigger('change');
      }
    });
    
    // 顯示恢復訊息
    showRestoreMessage();
    
  } catch (e) {
    console.log('Data Protection Guard: Error restoring server form data:', e);
  }
}

function showRestoreMessage() {
  // 在頁面頂部顯示恢復訊息
  var message = $('<div class="flash notice">表單資料已恢復，請修正違規內容後重新提交。</div>');
  $('.flash.error').after(message);
  
  // 3 秒後自動隱藏訊息
  setTimeout(function() {
    message.fadeOut();
  }, 3000);
}

// 清理舊的表單資料（超過 5 分鐘的資料）
function cleanupOldFormData() {
  var timestamp = localStorage.getItem('data_protection_form_timestamp');
  if (timestamp && (Date.now() - timestamp > 300000)) {
    localStorage.removeItem('data_protection_form_data');
    localStorage.removeItem('data_protection_form_timestamp');
  }
}

// 頁面載入時清理舊資料
$(document).ready(function() {
  cleanupOldFormData();
});
