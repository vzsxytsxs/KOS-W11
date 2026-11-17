# Removes from SysWOW64 the IME (Chinese, Japanese and Korean for 32-bit programs), the Internet Explorer F12 tools and the
# 32-bit speech (about 45 MB in ISO 4.0.0). The 64-bit versions stay.
param([string]$Mount, [string]$Iso)
$wow = Join-Path $Mount 'Windows\SysWOW64'
Clear-ImageFolderWithSxs $Mount (Join-Path $wow 'IME'), (Join-Path $wow 'F12'), (Join-Path $wow 'Speech_OneCore') 'wow64_*'
