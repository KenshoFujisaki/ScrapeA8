require 'csv'
require 'nokogiri'

# 引数チェック
unless ARGV.length == 2
  puts "$ ruby #{__FILE__} [input_csv_path] [output_path]"
  exit 1
end
print "[INFO] 入力のCSVファイルについて、注文金額および成果報酬額の桁区切りを除去しましたか？\n"
csv_path, output_file_path = ARGV

# ファイル書き出し
File.open(output_file_path, "w", :encoding => "Shift_JIS") do |f|

  # 入力CSVファイルから配列化
  # 入力CSVのカラム
  #   0:クリック日
  #   1:注文日
  #   2:確定日
  #   3:オーダーID
  #   4:サイト名
  #   5:成果種別
  #   6:プログラムId
  #   7:素材ID
  #   8:広告主名
  #   9:プログラム名
  #   10:注文金額
  #   11:成果報酬額
  #   12:ステータス
  #
  # 生成する配列
  # [
  #   {:click_date => "yyyy/mm/dd hh:mm:ss",
  #    :order_date => "yyyy/mm/dd hh:mm:ss",
  #    :fixed_date => "yyyy/mm/dd hh:mm:ss",
  #    :program_id => "sdddddddd",
  #    :program_name => "name",
  #    :order_price => "数字",
  #    :reward_price => "数字",
  #    :status => "キャンセル/確定/未確定",
  # ]

  input_array = CSV.read(csv_path, :encoding => "Shift_JIS:UTF-8", :headers => true).map{|cols|
    {
      :click_date   => cols[0],
      :order_date   => cols[1],
      :fixed_date   => cols[2],
      :program_id   => cols[6],
      :program_name => cols[9],
      :order_price  => cols[10],
      :reward_price => cols[11],
      :status       => cols[12],
    }
  }


  # 集計
  # {
  #  :プログラム名 => {
  #    :注文月 => {
  #      :number_of_occurrence => 報酬発生件数,
  #      :numebr_of_fixed      => 報酬確定件数,
  #      :number_of_canceled   => キャンセル件数,
  #      :number_of_unfixed    => 未確定件数,
  #      :price_of_occurrence  => 発生報酬額,
  #      :price_of_fixed       => 確定報酬額,
  #      :price_of_unfixed     => 未確定報酬額,
  #      :price_of_ordered     => 注文金額
  #    }
  #  }
  # }
  calced_hash = {}
  input_array.each do |program|
    key = program[:program_name]
    calced_hash[key] = {} unless calced_hash.has_key?(key)
    
    order_month = program[:order_date].match(/[0-9]+\/[0-9]+/)[0]
    reward_price = program[:reward_price].to_i
    order_price = program[:order_price].to_i

    is_fixed = program[:status] == "確定"
    is_canceled = program[:status] == "キャンセル"
    is_unfixed = program[:status] == "未確定"

    unless calced_hash[key].has_key?(order_month)
      calced_hash[key][order_month] = {
        :number_of_occurrence => 1,
        :number_of_fixed      => is_fixed ? 1 : 0,
        :number_of_canceled   => is_canceled ? 1 : 0,
        :number_of_unfixed    => is_unfixed ? 1 : 0,
        :price_of_occurrence  => reward_price,
        :price_of_fixed       => is_fixed ? reward_price : 0,
        :price_of_unfixed     => is_unfixed ? reward_price : 0,
        :price_of_ordered     => order_price
      }
    else
      calced_hash[key][order_month][:number_of_occurrence] += 1
      calced_hash[key][order_month][:price_of_occurrence] += reward_price
      calced_hash[key][order_month][:price_of_ordered] += order_price
      case program[:status]
      when "確定"
        calced_hash[key][order_month][:number_of_fixed] += 1
        calced_hash[key][order_month][:price_of_fixed] += reward_price
      when "キャンセル"
        calced_hash[key][order_month][:number_of_canceled] += 1
      when "未確定"
        calced_hash[key][order_month][:number_of_unfixed] += 1
        calced_hash[key][order_month][:price_of_unfixed] += reward_price
      end
    end
  end

  # CSVヘッダ出力
  list_of_order_month = calced_hash.map{|program, values| values.keys}.flatten.uniq.sort
  headers_per_month = [
    "報酬発生件数",
    "報酬確定件数",
    "キャンセル件数",
    "報酬未確定件数",
    "発生報酬額",
    "確定報酬額",
    "未確定報酬額",
    "注文金額"
  ]
  headers = ["プログラム名"] +
    list_of_order_month.map{|month| headers_per_month.map{|e| "#{month} #{e}"}}.flatten
  f.puts headers.join(",")

  # CSV内容出力
  calced_hash.each do |program_name, values|
    f.print "#{program_name},"

    list_of_order_month.each do |month|
      unless values.has_key?(month)
        f.print "0," * headers_per_month.length
        next
      end

      cache = values[month]
      f.print [
        cache[:number_of_occurrence],
        cache[:number_of_fixed],
        cache[:number_of_canceled],
        cache[:number_of_unfixed],
        cache[:price_of_occurrence],
        cache[:price_of_fixed],
        cache[:price_of_unfixed],
        cache[:price_of_ordered]
      ].join(",") + ","
    end
    f.puts ""
  end
end
