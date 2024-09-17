# 入力と出力ファイルのパス
$inputFile = "assets/Template_test.svg"
$outputFile = "assets/Template_test_sed.svg"

# ファイルの内容を読み込む
$content = Get-Content $inputFile

# 1つ目の置換: id="%...%" → id="_..._"
$content = $content -replace 'id="%([^%]+)%"', 'id="_$1_"'

# 2つ目の置換: id="_name[value]_" → id="_name_value_"
$content = $content -replace 'id="_(.+)\[(.+)\]_"', 'id="_$1_$2_"'

# 変換後の内容を新しいファイルに保存
Set-Content $outputFile -Value $content
