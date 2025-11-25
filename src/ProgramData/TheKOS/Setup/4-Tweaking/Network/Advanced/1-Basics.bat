powershell.exe Set-NetOffloadGlobalSetting -Chimney Disabled
powershell.exe Set-NetOffloadGlobalSetting -NetworkDirect Enabled
powershell.exe Set-NetOffloadGlobalSetting -NetworkDirectAcrossIPSubnets Allowed
powershell.exe Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disabled
powershell.exe Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled
powershell.exe Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled
powershell.exe Set-NetOffloadGlobalSetting -TaskOffload Disabled

netsh interface ipv6 set disabled
netsh interface 6to4 set state state=disabled undoonstop=enabled
netsh interface isatap set state disabled
netsh interface teredo set state disabled

netsh interface tcp set global rss=enabled
netsh interface tcp set global autotuninglevel=disabled
netsh interface tcp set global ecncapability=enabled
netsh interface tcp set global timestamps=disabled
netsh interface tcp set global initialrto=300
netsh interface tcp set global rsc=disabled
netsh interface tcp set global nonsackrttresiliency=enabled
netsh interface tcp set global maxsynretransmissions=2
netsh interface tcp set global fastopen=enabled
netsh interface tcp set global fastopenfallback=disabled
netsh interface tcp set global hystart=disabled
netsh interface tcp set global prr=enabled
netsh interface tcp set global pacingprofile=off

netsh int tcp set heuristics wsh=default forcews=default
netsh int tcp set security mpp=disabled profiles=disabled

netsh int udp set global uro=disabled
netsh int udp set global uso=disabled

netsh winsock set autotuning off

powershell.exe Disable-NetAdapterChecksumOffload -Name "*" -IncludeHidden -IpIPv4 -TcpIPv4 -TcpIPv6 -UdpIPv4 -UdpIPv6
powershell.exe Disable-NetAdapterEncapsulatedPacketTaskOffload -Name "*" -IncludeHidden
powershell.exe Disable-NetAdapterIPsecOffload -Name "*" -IncludeHidden
powershell.exe Disable-NetAdapterLso -Name "*" -IncludeHidden -IPv4 -IPv6
powershell.exe Disable-NetAdapterPowerManagement -Name "*" -IncludeHidden -ArpOffload -D0PacketCoalescing -DeviceSleepOnDisconnect -NSOffload -RsnRekeyOffload -SelectiveSuspend -WakeOnMagicPacket -WakeOnPattern
powershell.exe Disable-NetAdapterQos -Name "*" -IncludeHidden
powershell.exe Enable-NetAdapterRdma -Name "*" -IncludeHidden
powershell.exe Disable-NetAdapterRsc -Name "*" -IncludeHidden -IPv4 -IPv6
powershell.exe Enable-NetAdapterRss -Name "*" -IncludeHidden
powershell.exe Disable-NetAdapterSriov -Name "*" -IncludeHidden
powershell.exe Disable-NetAdapterUso -Name "*" -IncludeHidden -IPv4 -IPv6
powershell.exe Disable-NetAdapterVmq -Name "*" -IncludeHidden -IPv4 -IPv6

pause