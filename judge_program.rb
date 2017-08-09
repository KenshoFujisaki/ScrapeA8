require 'csv'
require 'nokogiri'
require 'mechanize'

# A8ログイン
def login_A8(user_id, password)
  agent = Mechanize.new
  agent.user_agent = 'Mac Safari'
  agent.get('https://www.a8.net/') do |page|
    page.form_with(name: 'asLogin') do |form|
      form.login = user_id
      form.passwd = password
    end.submit
  end
  return agent
end

# 成果報酬額/クリック率
def is_reward_of_clicks_over_50(doc)
  return doc.xpath('//*[@id="element"]/tbody/tr/td[3]').map do |node|
    !node.inner_text.match(/50以上/).nil?
  end.include?(true)
end

# LPのURL 取得
def get_url_of_landing_page(doc)
  return doc.xpath('//*[@id="code1"]').first.
    inner_text.match(/https:\/\/[^\"]*/)[0]
end

# リスティングNG条件の取得
def get_condition_of_listing_NG(doc)
  nodes = doc.xpath('//*[text()="NGキーワード"]/ancestor::tr[1]/td/div')
  case nodes.length
  when 0 then
    return "なし", true
  when 1 then
    ng_phrases = [
      "連想", "関わる", "かかわる", "関する", "準ずる", "順ずる", "掛け合わせ",
      "複合", "指名KW", "タイプミス", "誤字", "脱字", "類似"
    ]
    ng_keyword = nodes.first.inner_text
    is_ok_listing_ng = ng_keyword.match(/#{ng_phrases.join("|")}/).nil?
    return ng_keyword.gsub(/\"/,"\"\""), is_ok_listing_ng
  else
    raise "リスティングNG条件が複数取得されました。"
  end
end

# 成果報酬の取得
def get_reward(doc)
  return doc.xpath('//*[text()="成果報酬"]/ancestor::tr[1]/td/div').
    first.inner_text.gsub(/\"/,"\"\"")
end

# -----------------------------------------------------------------------------

# 引数チェック
unless ARGV.length == 4
  puts "$ ruby #{__FILE__} [user_id] [password] [input_csv_path] [output_path]"
  exit 1
end
user_id, password, csv_path, output_file_path = ARGV

# A8ログイン
agent = login_A8(user_id, password)

# ファイル書き出し
File.open(output_file_path, "w", :encoding => "SJIS") do |f|
  # ヘッダ行
  f.puts [
    "プログラムID",
    "成果報酬額/クリック率50以上か？",
    "LPのURL",
    "リスティングNG条件",
    "リスティングNG条件厳しすぎないか？",
    "成果報酬",
    "アクセプトするか？"
  ].join(",")

  # 入力CSVファイルからプログラムIDの取得
  program_ids = CSV.read(csv_path).map{|e| e[0]}

  # 各案件ごとに判定
  program_ids.each_with_index do |program_id, index|
    # 進捗表示
    print "[INFO] (#{index + 1}/#{program_ids.length}) #{program_id}"
    is_accepted = false

    begin
      f.print "\"#{program_id}\","

      # 「広告リンク作成」ページ
      html = agent.get("https://pub.a8.net/a8v2/asLinkAction.do?insId=#{program_id}").content.toutf8
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
      is_ok_reward = is_reward_of_clicks_over_50(doc)
      f.print "#{(is_ok_reward ? "○" : "")},"
      f.print "\"#{get_url_of_landing_page(doc)}\","

      # 「提携情報の表示」ページ
      html = agent.get("https://pub.a8.net/a8v2/asProgramDetailAction.do?insId=#{program_id}").content.toutf8
      doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
      ng_keyword, is_ok_listing_ng = get_condition_of_listing_NG(doc)
      f.print "\"#{ng_keyword}\","
      f.print "#{(is_ok_listing_ng ? "○" : "")},"
      f.print "\"#{get_reward(doc)}\","

      # アクセプト判定
      is_accepted = is_ok_reward && is_ok_listing_ng
    rescue => e
      STDERR.puts "[ERROR] #{program_id}: #{e} #{e.backtrace}"
    ensure
      f.print "#{(is_accepted ? "○" : "")}\n"
      print "#{(is_accepted ? " is accepted." : "")}\n"
      sleep(1)
    end
  end
end
