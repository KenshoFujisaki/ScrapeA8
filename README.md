# ScrapeA8

## 環境

* ruby 2.1.0+
* `bundle install`

## 使用法

* 案件判定
```
bundle exec ruby judge_program.rb [user_id@A8] [password@A8] [csv path of program_id list]
```

# 使用例

* 案件判定
    * 入力
        ```
        s00000013697004
        s00000008174009
        ```
    * 実行
        ```
        bundle exec ruby judge_program.rb user_id password program_list.csv | nkf -s > result.csv
        cat result.csv
        ```
    * 出力
        ```
        プログラムID,成果報酬額/クリック率50以上か？,LPのURL,リスティングNG条件,リスティングNG条件は厳しすぎないか？
        s00000013697004,○,https://px.a8.net/svt/ejp?a8mat=2TMQM8+AJUKQA+2XOQ+NTJWY,なし,○,
        s00000008174009,,https://px.a8.net/svt/ejp?a8mat=2TMQLU+E22GZ6+1R2K+1HONM9,ホメオバウ・Homeobeau,○,
        ```
