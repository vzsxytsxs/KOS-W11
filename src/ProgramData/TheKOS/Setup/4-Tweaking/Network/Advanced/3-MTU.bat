@echo off
netsh interface ipv4 set subinterface "1" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "10" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "12" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "16" mtu=1500 store=persistent
netsh interface ipv4 set subinterface "33" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "1" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "10" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "12" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "16" mtu=1500 store=persistent
netsh interface ipv6 set subinterface "33" mtu=1500 store=persistent
netsh interface ipv4 show interfaces
netsh interface ipv6 show interfaces

pause
