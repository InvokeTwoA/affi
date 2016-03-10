$ ->
  # カレンダー日付選択
  $('input.datepicker').datepicker
    altFormat: "yy-mm-dd"
    dateFormat: "yy/mm/dd"

  # 検索条件変更時の自動更新
  $('#search-form[data-remote=true]').change ->
    $('#search-form').submit()
    return
