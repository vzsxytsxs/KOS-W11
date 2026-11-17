# Removes the Chinese, Japanese and Korean fonts (about 260 MB in ISO 4.0.0) from the Fonts folder, WinSxS and the
# registry. MS Gothic stays, because removing it breaks text. Without the others, Chinese and Korean text shows
# up as squares.
param([string]$Mount, [string]$Iso)
$fonts = 'mingliub.ttc', 'mingliu.ttc', 'simsun.ttc', 'simsunb.ttf', 'simsunextg.ttf', 'simhei.ttf', 'simkai.ttf', 'simfang.ttf',
    'msyh.ttc', 'msyhbd.ttc', 'msyhl.ttc', 'msjh.ttc', 'msjhbd.ttc', 'msjhl.ttc', 'kaiu.ttf', 'deng.ttf', 'dengb.ttf', 'dengl.ttf',
    'yugothb.ttc', 'yugothl.ttc', 'yugothm.ttc', 'yugothr.ttc', 'meiryo.ttc', 'meiryob.ttc', 'msmincho.ttc', 'yumin.ttf', 'yumindb.ttf', 'yuminl.ttf',
    'malgun.ttf', 'malgunbd.ttf', 'malgunsl.ttf', 'gulim.ttc', 'batang.ttc'
Remove-ImageFiles (Join-Path $Mount 'Windows\Fonts') $fonts
# The fonts in the Fonts folder are hardlinks to WinSxS: without deleting them there too, the ISO does not shrink
foreach ($dir in Get-ChildItem (Join-Path $Mount 'Windows\WinSxS') -Directory -Filter '*_microsoft-windows-f*') {
    $found = @($fonts | Where-Object { [IO.File]::Exists((Join-Path $dir.FullName $_)) })
    if ($found) { Remove-ImageFiles $dir.FullName $found }
}
Edit-ImageRegistry $Mount 'SOFTWARE' {
    param($root)
    $key = "$root\Microsoft\Windows NT\CurrentVersion\Fonts"
    $values = (Get-Item $key).Property
    foreach ($name in $values) { if ((Get-ItemPropertyValue $key $name) -in $fonts) { Remove-ItemProperty $key $name } }
}
