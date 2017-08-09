# ScrapeA8

## 環境

* ruby 2.1.0+
* `bundle install`

## 使用法

* 案件判定
```
bundle exec ruby judge_program.rb [user_id] [password] [input_csv_path] [output_path]
```

# 使用例

* 案件判定
    * 入力
        ```
        s00000000204020
        s00000001637174
        s00000001637190
        s00000001637222
        s00000001637262
        s00000001637284
        ```
        ...
    * 実行
        ```
        bundle exec ruby judge_program.rb user_id password program_list.csv result_list.csv
        ```
    * 標準出力
        ```
        [INFO] (1/67) s00000000204020 is accepted.
        [INFO] (2/67) s00000001637174
        [INFO] (3/67) s00000001637190 is accepted.
        [INFO] (4/67) s00000001637222 is accepted.
        [INFO] (5/67) s00000001637262
        [INFO] (6/67) s00000001637284
        ```
        ...
    * 出力ファイル
        ```
        プログラムID,成果報酬額/クリック率50以上か？,LPのURL,リスティングNG条件,リスティングNG条件厳しすぎないか？,成果報酬,アクセプトするか？
        "s00000000204020",○,"https://px.a8.net/svt/ejp?a8mat=2TP1KS+9LWV8Y+1KO+3B5WQ9","社名・商品名・サービス関連の商標キーワード",○,"初回購入2980円",○
        "s00000001637174",,"https://px.a8.net/svt/ejp?a8mat=2TP1KS+AEHOAA+CMR+C8P9OX","なし",○,"商品購入金額の１０％",
        "s00000001637190",○,"https://px.a8.net/svt/ejp?a8mat=2TP1KS+ASS2SY+CMR+EVUC5U","なし",○,"商品購入金額の１０％",○
        "s00000001637222",○,"https://px.a8.net/svt/ejp?a8mat=2TP1KS+AKG0C2+CMS+3N1PYQ","なし",○,"商品購入金額の１０％",○
        "s00000001637262",,"https://px.a8.net/svt/ejp?a8mat=2TP1KS+ALMVJM+CMS+A95LXE","なし",○,"商品購入金額の１０％",
        "s00000001637284",,"https://px.a8.net/svt/ejp?a8mat=2TP1KS+9JJ4TU+CMS+DW99C1","なし",○,"購入(税抜)10％",
        ```
