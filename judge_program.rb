require 'csv'
require 'nokogiri'
require 'mechanize'

# 引数チェック
unless ARGV.length == 3
  puts "$ ruby #{__FILE__} [user_id@A8] [password@A8] [csv path of program_id list]"
  exit 1
end
user_id = ARGV[0]
password = ARGV[1]
csv_path = ARGV[2]

# CSV読み込み
program_ids = CSV.read(csv_path).map{|e| e[0]}

# A8ログイン
agent = Mechanize.new
agent.user_agent = 'Mac Safari'
agent.get('https://www.a8.net/') do |page|
  page.form_with(name: 'asLogin') do |form|
    form.login = user_id
    form.passwd = password
  end.submit
end

# ヘッダ行
puts "プログラムID,成果報酬額/クリック率50以上か？,LPのURL,リスティングNG条件,リスティングNG条件厳しすぎないか？"

# 各案件ごとに判定
program_ids.each do |program_id|
  print "\"#{program_id}\","
  begin

    # 成果報酬額/クリック率 の判定
    url = "https://pub.a8.net/a8v2/asLinkAction.do?insId=#{program_id}"
    html = agent.get("#{url}").content.toutf8
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    is_over_50 = doc.xpath('//*[@id="element"]/tbody/tr/td[3]').map do |node|
      !node.inner_text.match(/50以上/).nil?
    end.include?(true)
    print "#{(is_over_50 ? "○" : "")},"

    # LPのURL 取得
    url_of_lp = doc.xpath('//*[@id="code1"]').first.inner_text.match(/https:\/\/[^\"]*/)[0]
    print "\"#{url_of_lp}\","

    # リスティングNG条件の取得
    url = "https://pub.a8.net/a8v2/asProgramDetailAction.do?insId=#{program_id}"
    html = agent.get("#{url}").content.toutf8
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    nodes = doc.xpath('//*[text()="NGキーワード"]/ancestor::tr[1]/td/div')
    case nodes.length
    when 0 then
      print "なし,○,"
    when 1 then
      ng_keyword = nodes.first.inner_text
      is_ok_listing_ng = ng_keyword.match(/連想|関する|かかわる|関わる|準ずる|順ずる|掛け合わせ|複合|指名KW|タイプミス｜誤字|脱字|類似/).nil?
      print "\"#{ng_keyword.gsub(/\"/,"\"\"")}\",#{(is_ok_listing_ng ? "○" : "")},"
    else
      raise "リスティングNG条件が複数取得されました。"
    end

  rescue => e
    STDERR.puts "[ERROR] #{program_id}: #{e} #{e.backtrace}"
  ensure
    print "\n"
    sleep(1)
  end
end

