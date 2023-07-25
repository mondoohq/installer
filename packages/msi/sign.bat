rem Create Certs
MakeCert -n "CN=Mondoo, O=Mondoo, L=SF, S=CA, C=USA" -r -h 0 -eku "1.3.6.1.5.5.7.3.3,1.3.6.1.4.1.311.10.3.13" -e 12/31/2100 -sv C:\MyKey.pvk C:\MyKey.cer

rem Create a Personal Information Exchange (.pfx) file using Pvk2Pfx.exe
Pvk2Pfx -pvk MyKey.pvk -pi test -spc C:\MyKey.cer -pfx C:\MyKey.pfx -po test

rem Sign package
SignTool sign -debug -a -fd SHA256 -f C:\MyKey.pfx -p test C:\dist\hello-agent.appx

rem sign msi package
Signtool sign -debug -a -fd SHA256 -f C:\MyKey.pfx -p test C:\dist\hello-agent.msi