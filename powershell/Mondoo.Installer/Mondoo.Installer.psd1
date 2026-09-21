# Copyright (c) 2022 Mondoo, Inc. All rights reserved.
# Licensed under the Apache 2 License.

@{

    # Script module or binary module file associated with this manifest.
    RootModule = './Mondoo.Installer.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.4.2'
    
    # Supported PSEditions
    # CompatiblePSEditions = @()
    
    # ID used to uniquely identify this module
    GUID = '53ec5a21-43bd-4279-8e23-59e8bc9802e6'
    
    # Author of this module
    Author = 'Mondoo, Inc'
    
    # Company or vendor of this module
    CompanyName = 'Mondoo, Inc'
    
    # Copyright statement for this module
    Copyright = 'Copyright Mondoo, Inc. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'The Mondoo.Installer module makes it easier to install and update Mondoo packages. Scripts for Mondoo.
You can use a single command ''Install-Mondoo'' to install mql and cnspec packages.'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Install-Mondoo'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    # FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
    
        PSData = @{
    
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Mondoo', 'cloud', 'Windows', 'security', 'vulnerability', 'Azure')
    
            # A URL to the license for this module.
            # LicenseUri = ''
    
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/mondoohq/installer/'
    
            # A URL to an icon representing this module.
            IconUri = 'https://avatars.githubusercontent.com/u/99198514?s=200&v=4'
    
            # ReleaseNotes of this module
            # ReleaseNotes = ''
    
        } # End of PSData hashtable
    
    } # End of PrivateData hashtable
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
    
    }

# SIG # Begin signature block
# MII9RQYJKoZIhvcNAQcCoII9NjCCPTICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDIWQWnFK/iLLgx
# lqcZgYdbPXD+zc4t94QeJhwug65R+qCCIeowggXMMIIDtKADAgECAhBUmNLR1FsZ
# lUgTecgRwIeZMA0GCSqGSIb3DQEBDAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVu
# dGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAy
# MDAeFw0yMDA0MTYxODM2MTZaFw00NTA0MTYxODQ0NDBaMHcxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jv
# c29mdCBJZGVudGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALORKgeD
# Bmf9np3gx8C3pOZCBH8Ppttf+9Va10Wg+3cL8IDzpm1aTXlT2KCGhFdFIMeiVPvH
# or+Kx24186IVxC9O40qFlkkN/76Z2BT2vCcH7kKbK/ULkgbk/WkTZaiRcvKYhOuD
# PQ7k13ESSCHLDe32R0m3m/nJxxe2hE//uKya13NnSYXjhr03QNAlhtTetcJtYmrV
# qXi8LW9J+eVsFBT9FMfTZRY33stuvF4pjf1imxUs1gXmuYkyM6Nix9fWUmcIxC70
# ViueC4fM7Ke0pqrrBc0ZV6U6CwQnHJFnni1iLS8evtrAIMsEGcoz+4m+mOJyoHI1
# vnnhnINv5G0Xb5DzPQCGdTiO0OBJmrvb0/gwytVXiGhNctO/bX9x2P29Da6SZEi3
# W295JrXNm5UhhNHvDzI9e1eM80UHTHzgXhgONXaLbZ7LNnSrBfjgc10yVpRnlyUK
# xjU9lJfnwUSLgP3B+PR0GeUw9gb7IVc+BhyLaxWGJ0l7gpPKWeh1R+g/OPTHU3mg
# trTiXFHvvV84wRPmeAyVWi7FQFkozA8kwOy6CXcjmTimthzax7ogttc32H83rwjj
# O3HbbnMbfZlysOSGM1l0tRYAe1BtxoYT2v3EOYI9JACaYNq6lMAFUSw0rFCZE4e7
# swWAsk0wAly4JoNdtGNz764jlU9gKL431VulAgMBAAGjVDBSMA4GA1UdDwEB/wQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTIftJqhSobyhmYBAcnz1AQ
# T2ioojAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0BAQwFAAOCAgEAr2rd5hnn
# LZRDGU7L6VCVZKUDkQKL4jaAOxWiUsIWGbZqWl10QzD0m/9gdAmxIR6QFm3FJI9c
# Zohj9E/MffISTEAQiwGf2qnIrvKVG8+dBetJPnSgaFvlVixlHIJ+U9pW2UYXeZJF
# xBA2CFIpF8svpvJ+1Gkkih6PsHMNzBxKq7Kq7aeRYwFkIqgyuH4yKLNncy2RtNwx
# AQv3Rwqm8ddK7VZgxCwIo3tAsLx0J1KH1r6I3TeKiW5niB31yV2g/rarOoDXGpc8
# FzYiQR6sTdWD5jw4vU8w6VSp07YEwzJ2YbuwGMUrGLPAgNW3lbBeUU0i/OxYqujY
# lLSlLu2S3ucYfCFX3VVj979tzR/SpncocMfiWzpbCNJbTsgAlrPhgzavhgplXHT2
# 6ux6anSg8Evu75SjrFDyh+3XOjCDyft9V77l4/hByuVkrrOj7FjshZrM77nq81YY
# uVxzmq/FdxeDWds3GhhyVKVB0rYjdaNDmuV3fJZ5t0GNv+zcgKCf0Xd1WF81E+Al
# GmcLfc4l+gcK5GEh2NQc5QfGNpn0ltDGFf5Ozdeui53bFv0ExpK91IjmqaOqu/dk
# ODtfzAzQNb50GQOmxapMomE2gj4d8yu8l13bS3g7LfU772Aj6PXsCyM2la+YZr9T
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAbN9KjU
# pn2guJdDAAAABs30MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDMwHhcNMjYwOTIwMDYxMjU2WhcNMjYwOTIz
# MDYxMjU2WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA3JQa
# svHnJC0JtM4wh+GC3fbf9KtyzmxphRKyRADXpDLkw+ZtaUUn1DTV8Dt/YCxrrBDY
# 6rvHNgy5upQC0h73J9dHO0/in02GIw2/pWnDppNITfq5XW/dKX6bJ1z/8C3pGxuf
# x0aN+Z19mWhV35L7jHKdJUtKIu8awoQyRkQJj+/9bMpX+znidq5TtiYhcX1gCoOv
# kT0AcCF0foZnKZhGWEpXKYTQPtLTGR+hb+63JupII2M/m6Akb78Q0xXBA3cOC3TS
# tJWd6BeHQWi1fHPCKvcAxiYlXdBNG1Ovb0SCwYzqgBHfqf5wr/iQZz2ixy97HdCc
# DD7R0gN5Bman3jlCrOX1KkKrQSLzB0KvIu4hXNeQ+oYfG6kCb0JpYgQcqnAmbTvG
# 1xWxZ2YX9PUFVGko6P100VpwW580kRX/Spxr76vTF0LZoxcr/QmCgUaiyKW2dwzo
# behIReE2AS4Rw/T0xrx0Xihe18faHcpaBtGVc7ifGAmXNuyELcixtpXPDA+FAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUuMwIFVvqs6FaBuaxIxXbqouhwlMwHwYDVR0jBBgw
# FoAUpEMMf3ZapYXnPo0oDwwXokVpcMYwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwMy5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIw
# MDMuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAGzC36HIKNSq/adzxPkrzhC5vbrFbIN6LwmFKtrWVSMO
# rDVGIQA/8wMfGkg1a5zXOyNufLf19eFfBX5Dy08A5Ug+I4DpgDdpmxg+NCwpA7vF
# 2Grphm0oZ/raoE0yAimGORMid1J0rBOz+QXumuKl8My9OdSZfuS29eaiTgnJJInp
# CpQAvQCi3952obtmdG1EPNMTP2orWzqZ/5iepDaflGhsVta0yMe7U4cvb/Pro5MP
# 15awL0KvWzRF+zgBJpeMqorxwhhIetLMZSp30CUe+DVOz6cXTxEzP5ubti01iUK2
# CCdzQQSBrsgbEoNfpCcy0xxWFkZnBY09WQEEPsYSTH/cABw8vRpUjYREcsEUsY57
# iHC8E/3PbSvmVE4t7imVIUavoqJCN5r4VkNliOgabDc/NFwdZr6ifJr1DQQmK4w7
# Yb5yKYPRqQBuBE3rgdY6nKCZYx4Qufe5+IIrM4oM9R/NmYdDl/z66I0kn/ibLKY3
# QcbS2PLY/7mfQIFT+GWk0LIBnPHryS587dFDQys1BM2gV8HNM7xkHIMrUn/ikrf1
# s0cHx4fWGyMhM7DHg4g85+je2kipp3TojhK2fap0gyF5ZuNp3cpUFXRUbs9Qe7xu
# zTgBCvP6hec9zQ/HqN/Qhvann7gY15V3+uQQcHW5SVx6FfF8w5wW2NeC/cuOZqIN
# MIIGojCCBIqgAwIBAgITMwAGzfSo1KZ9oLiXQwAAAAbN9DANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAzMB4X
# DTI2MDkyMDA2MTI1NloXDTI2MDkyMzA2MTI1NlowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBANyUGrLx5yQtCbTOMIfhgt323/Srcs5saYUSskQA
# 16Qy5MPmbWlFJ9Q01fA7f2Asa6wQ2Oq7xzYMubqUAtIe9yfXRztP4p9NhiMNv6Vp
# w6aTSE36uV1v3Sl+mydc//At6Rsbn8dGjfmdfZloVd+S+4xynSVLSiLvGsKEMkZE
# CY/v/WzKV/s54nauU7YmIXF9YAqDr5E9AHAhdH6GZymYRlhKVymE0D7S0xkfoW/u
# tybqSCNjP5ugJG+/ENMVwQN3Dgt00rSVnegXh0FotXxzwir3AMYmJV3QTRtTr29E
# gsGM6oAR36n+cK/4kGc9oscvex3QnAw+0dIDeQZmp945Qqzl9SpCq0Ei8wdCryLu
# IVzXkPqGHxupAm9CaWIEHKpwJm07xtcVsWdmF/T1BVRpKOj9dNFacFufNJEV/0qc
# a++r0xdC2aMXK/0JgoFGosiltncM6G3oSEXhNgEuEcP09Ma8dF4oXtfH2h3KWgbR
# lXO4nxgJlzbshC3IsbaVzwwPhQIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFLjMCBVb6rOh
# WgbmsSMV26qLocJTMB8GA1UdIwQYMBaAFKRDDH92WqWF5z6NKA8MF6JFaXDGMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIw
# MDMuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBBT0MlMjBDQSUyMDAzLmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQBswt+hyCjUqv2n
# c8T5K84Qub26xWyDei8JhSra1lUjDqw1RiEAP/MDHxpINWuc1zsjbny39fXhXwV+
# Q8tPAOVIPiOA6YA3aZsYPjQsKQO7xdhq6YZtKGf62qBNMgIphjkTIndSdKwTs/kF
# 7pripfDMvTnUmX7ktvXmok4JySSJ6QqUAL0Aot/edqG7ZnRtRDzTEz9qK1s6mf+Y
# nqQ2n5RobFbWtMjHu1OHL2/z66OTD9eWsC9Cr1s0Rfs4ASaXjKqK8cIYSHrSzGUq
# d9AlHvg1Ts+nF08RMz+bm7YtNYlCtggnc0EEga7IGxKDX6QnMtMcVhZGZwWNPVkB
# BD7GEkx/3AAcPL0aVI2ERHLBFLGOe4hwvBP9z20r5lROLe4plSFGr6KiQjea+FZD
# ZYjoGmw3PzRcHWa+onya9Q0EJiuMO2G+cimD0akAbgRN64HWOpygmWMeELn3ufiC
# KzOKDPUfzZmHQ5f8+uiNJJ/4myymN0HG0tjy2P+5n0CBU/hlpNCyAZzx68kufO3R
# Q0MrNQTNoFfBzTO8ZByDK1J/4pK39bNHB8eH1hsjITOwx4OIPOfo3tpIqad06I4S
# tn2qdIMheWbjad3KVBV0VG7PUHu8bs04AQrz+oXnPc0Px6jf0Ib2p5+4GNeVd/rk
# EHB1uUlcehXxfMOcFtjXgv3LjmaiDTCCBygwggUQoAMCAQICEzMAAAAYDeuRVamK
# AJgAAAAAABgwDQYJKoZIhvcNAQEMBQAwYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZl
# cmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTAeFw0yNjAzMjYxODExMzJaFw0z
# MTAzMjYxODExMzJaMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBB
# T0MgQ0EgMDMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDIgNpgNFai
# if2VWeWP5I6PnFXxJ/lB37fJR55GCvR7GLZBMkBijbiKVwgpBI3xM5nf484znH/q
# ncJ+OCq6y3jgnQW+R8Zd7U+7LjlrmcskalzSQ0ghMxEpnBW8/HHs2V8ZJzQk6HP+
# SDsbvsL7LdlH/eO2l4mknhDBwr0Z/Q966TvEth5b8kCxj1vqiV4YNthLGRqZR9u2
# fK/yBMWu83p6O4uo2Edg++gEew5IL7vnnnKFqmSh/R9vPJy3WF1YcZewAUx8sXZN
# Unx3ZhVg59l2LpitPiwzE6FMqIsqaEvVe3MzuFd2a/uWDZH6VbDyUiRK78mIg1DQ
# YA9zDEyyBFcNI+nxVSzglvL6u7PRuNqgcV3sf6ELxw89ysQM/Z4R1hRFWXRpyOWK
# KAKtfBHTk0UnNiPcxmLMMYs8jeUjOidfVPjTIry/UVwnwxdlkK85cZfBEMYZ/DBN
# OwdomP459Y1n8izKkbhsa+p4lw+cQVxATBFx9ggR79HhryT7HDmpPLvkJvBZ4wW4
# CW32UT2SMyDe28nIOU3m+hfHlVeKcLBQcym5VoRDjIcCVI7uqgGW2PNME0cfei8z
# CwCy6HCsssJWFS7eg/YbFhnATJcyWfMrkNuAbMfMN8Npg8crS6jVVowyD0GG5zdg
# i+uQVcSK/638mA1xEYK3pnIoQgO09uuDBwIDAQABo4IB3DCCAdgwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBSkQwx/dlqlhec+jSgP
# DBeiRWlwxjBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBkG
# CSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYD
# VR0jBBgwFoAU2UEpsA8PY2zvadf1zSmepEhqMOYwcAYDVR0fBGkwZzBloGOgYYZf
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# SUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyMS5jcmww
# fQYIKwYBBQUHAQEEcTBvMG0GCCsGAQUFBzAChmFodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3J0MA0GCSqGSIb3DQEBDAUAA4IC
# AQBxxyBW+X6mhdRiSwD9PMMWcGUAnx5/QUwnNvZdFGEX+4DRDIr9WCh4C87wHtw+
# lg1D3uzK10DstPX0LFLBFAC3vWMYX4ImXwoLhoR0xlN8mUdorJ3bgnpCJWuI1531
# Z1rCwPuUrSkBxfOIGDk3p2ECb3Ho/xHi5PRSR/OUrWuQHwXiaXMTuXu3IRLezwVk
# ZpFmNwYRD57R9Nx2F/yM7tzOY0Hh0hGCaYEK38/6FrS0SXadXWyDUCfn5XOGACRj
# UCnHx+JQUG0f4SHD+iblpAI0gl+ZHnVmdXXxHTZeTa0CYCIhFxKP2922s0g6zLme
# iV13LWUmtt/UF7TrWXpMi2/0UNniaDoH7rnPGRV5xVX8uXy4sZii4aswzqPM7Y7+
# mzcranqZ8EjZk5gjLhQ3A2sZaprlOu8CaRmyfcIiVH7zVfgAvm81MWXFziAf7my7
# QOvnyEFPGddq8MSfPtfRyw/Uq3uH6KpoaJNIfPYH6fceZSi53Rat1A9grExq3ROj
# hhSpTcchuBItAMNVPxoKNbUm+iR/X3XkL+9WQginjyHe+hXLclY8vAGXFD1p40Pq
# MIpAYsmEJBFKW9df4//1N5oQDr/FY9IBJl/oSS979i5rtT7NZz9KvYraCPRBGs0Q
# Cy+sWvgQa0coM70QJVLeVwmSxUO/0od0w9Qry7bSLrxGoDCCB54wggWGoAMCAQIC
# EzMAAAAHh6M0o3uljhwAAAAAAAcwDQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMC
# VVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWlj
# cm9zb2Z0IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1
# dGhvcml0eSAyMDIwMB4XDTIxMDQwMTIwMDUyMFoXDTM2MDQwMTIwMTUyMFowYzEL
# MAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIG
# A1UEAxMrTWljcm9zb2Z0IElEIFZlcmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAy
# MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALLwwK8ZiCji3VR6TEls
# aQhVCbRS/3pK+MHrJSj3Zxd3KU3rlfL3qrZilYKJNqztA9OQacr1AwoNcHbKBLbs
# QAhBnIB34zxf52bDpIO3NJlfIaTE/xrweLoQ71lzCHkD7A4As1Bs076Iu+mA6cQz
# sYYH/Cbl1icwQ6C65rU4V9NQhNUwgrx9rGQ//h890Q8JdjLLw0nV+ayQ2Fbkd242
# o9kH82RZsH3HEyqjAB5a8+Ae2nPIPc8sZU6ZE7iRrRZywRmrKDp5+TcmJX9MRff2
# 41UaOBs4NmHOyke8oU1TYrkxh+YeHgfWo5tTgkoSMoayqoDpHOLJs+qG8Tvh8Sni
# fW2Jj3+ii11TS8/FGngEaNAWrbyfNrC69oKpRQXY9bGH6jn9NEJv9weFxhTwyvx9
# OJLXmRGbAUXN1U9nf4lXezky6Uh/cgjkVd6CGUAf0K+Jw+GE/5VpIVbcNr9rNE50
# Sbmy/4RTCEGvOq3GhjITbCa4crCzTTHgYYjHs1NbOc6brH+eKpWLtr+bGecy9Crw
# Qyx7S/BfYJ+ozst7+yZtG2wR461uckFu0t+gCwLdN0A6cFtSRtR8bvxVFyWwTtgM
# MFRuBa3vmUOTnfKLsLefRaQcVTgRnzeLzdpt32cdYKp+dhr2ogc+qM6K4CBI5/j4
# VFyC4QFeUP2YAidLtvpXRRo3AgMBAAGjggI1MIICMTAOBgNVHQ8BAf8EBAMCAYYw
# EAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFNlBKbAPD2Ns72nX9c0pnqRIajDm
# MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wGQYJKwYBBAGC
# NxQCBAweCgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTI
# ftJqhSobyhmYBAcnz1AQT2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHkl
# MjBWZXJpZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHkl
# MjAyMDIwLmNybDCBwwYIKwYBBQUHAQEEgbYwgbMwgYEGCCsGAQUFBzAChnVodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElk
# ZW50aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0
# aG9yaXR5JTIwMjAyMC5jcnQwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1p
# Y3Jvc29mdC5jb20vb2NzcDANBgkqhkiG9w0BAQwFAAOCAgEAfyUqnv7Uq+rdZgrb
# VyNMul5skONbhls5fccPlmIbzi+OwVdPQ4H55v7VOInnmezQEeW4LqK0wja+fBzn
# ANbXLB0KrdMCbHQpbLvG6UA/Xv2pfpVIE1CRFfNF4XKO8XYEa3oW8oVH+KZHgIQR
# IwAbyFKQ9iyj4aOWeAzwk+f9E5StNp5T8FG7/VEURIVWArbAzPt9ThVN3w1fAZkF
# 7+YU9kbq1bCR2YD+MtunSQ1Rft6XG7b4e0ejRA7mB2IoX5hNh3UEauY0byxNRG+f
# T2MCEhQl9g2i2fs6VOG19CNep7SquKaBjhWmirYyANb0RJSLWjinMLXNOAga10n8
# i9jqeprzSMU5ODmrMCJE12xS/NWShg/tuLjAsKP6SzYZ+1Ry358ZTFcx0FS/mx2v
# SoU8s8HRvy+rnXqyUJ9HBqS0DErVLjQwK8VtsBdekBmdTbQVoCgPCqr+PDPB3xaj
# Ynzevs7eidBsM71PINK2BoE2UfMwxCCX3mccFgx6UsQeRSdVVVNSyALQe6PT1241
# 8xon2iDGE81OGCreLzDcMAZnrUAx4XQLUz6ZTl65yPUiOh3k7Yww94lDf+8oG2oZ
# mDh5O1Qe38E+M3vhKwmzIeoB1dVLlz4i3IpaDcR+iuGjH2TdaC1ZOmBXiCRKJLj4
# DT2uhJ04ji+tHD6n58vhavFIrmcxghqxMIIarQIBATBxMFoxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jv
# c29mdCBJRCBWZXJpZmllZCBDUyBBT0MgQ0EgMDMCEzMABs30qNSmfaC4l0MAAAAG
# zfQwDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgr4zOdXS8ZgUgCkJAq4tC
# JvEPPleACIt7sM/BkafCe/EwDQYJKoZIhvcNAQEBBQAEggGAl96SicxONUN1wv6T
# aBjZpw+D6CIUweex/O2OGoiq759DetcgKNmE/ofEsn1iuhJTgra0TSi9yoqm8msw
# 3Yssw2b9q2GCtRep/JQHcICA8T2Iajgp4hpAz1riGMDW07GTN53fQLBKc2GmTP4F
# nlI07JnTbUfcIBrIGGbfopK7vQFGMsZ5Cr56vy2UtBAWvXdqqjmbTvUZ3gnBUP7M
# /YdxLkXO3Dlc6GZy4SaIr9uQki2468olIVoh7Y6xa8oDIQQkoS3Eeco46sxwT0rK
# vw9NHrAyqOoNoYcwRehz1HFW8ClEbIZEAY9HPGY34JFm5pvnvVPJlRev0MfFmFYa
# xemHvG7FfCg6FEjUvY+SuKYlfxX/m6YqAJo1V6NHtoW970GlOaxlvlih+eLUAA17
# h95BB6qkC24ctBX5ccs1eNyZWzET73rGcWy+qnBgdWcAGp0FcxxXFNoZnENi9e5D
# z9IAYXXsjfKeNkkXdbavLhJoXyM86bopu5c+An3gNIab9tSZoYIYMTCCGC0GCisG
# AQQBgjcDAwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMHtc4nE8tAQWvchDNd6BwHVK9tia6yqKAdt1
# 6EKFIgylfkcPQ/4mjKAfn0UP0rvjfAIGaqlLGJwvGBMyMDI2MDkyMTIwMzIwNy45
# NTNaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046N0EwMC0wNUUwLUQ5NDcxNTAzBgNVBAMT
# LE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5oIIP
# ITCCB4IwggVqoAMCAQICEzMAAAAF5c8P/2YuyYcAAAAAAAUwDQYJKoZIhvcNAQEM
# BQAwdzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjFIMEYGA1UEAxM/TWljcm9zb2Z0IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDIwMB4XDTIwMTExOTIwMzIzMVoXDTM1
# MTExOTIwNDIzMVowYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0
# YW1waW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCe
# fOdSY/3gxZ8FfWO1BiKjHB7X55cz0RMFvWVGR3eRwV1wb3+yq0OXDEqhUhxqoNv6
# iYWKjkMcLhEFxvJAeNcLAyT+XdM5i2CgGPGcb95WJLiw7HzLiBKrxmDj1EQB/mG5
# eEiRBEp7dDGzxKCnTYocDOcRr9KxqHydajmEkzXHOeRGwU+7qt8Md5l4bVZrXAhK
# +WSk5CihNQsWbzT1nRliVDwunuLkX1hyIWXIArCfrKM3+RHh+Sq5RZ8aYyik2r8H
# xT+l2hmRllBvE2Wok6IEaAJanHr24qoqFM9WLeBUSudz+qL51HwDYyIDPSQ3SeHt
# Kog0ZubDk4hELQSxnfVYXdTGncaBnB60QrEuazvcob9n4yR65pUNBCF5qeA4QwYn
# ilBkfnmeAjRN3LVuLr0g0FXkqfYdUmj1fFFhH8k8YBozrEaXnsSL3kdTD01X+4Lf
# IWOuFzTzuoslBrBILfHNj8RfOxPgjuwNvE6YzauXi4orp4Sm6tF245DaFOSYbWFK
# 5ZgG6cUY2/bUq3g3bQAqZt65KcaewEJ3ZyNEobv35Nf6xN6FrA6jF9447+NHvCje
# WLCQZ3M8lgeCcnnhTFtyQX3XgCoc6IRXvFOcPVrr3D9RPHCMS6Ckg8wggTrtIVnY
# 8yjbvGOUsAdZbeXUIQAWMs0d3cRDv09SvwVRd61evQIDAQABo4ICGzCCAhcwDgYD
# VR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRraSg6NS9I
# Y0DPe9ivSek+2T3bITBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYz
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnku
# aHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIA
# QwBBMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUyH7SaoUqG8oZmAQHJ89Q
# EE9oqKIwgYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9u
# JTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5jcmwwgZQG
# CCsGAQUFBwEBBIGHMIGEMIGBBggrBgEFBQcwAoZ1aHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJZGVudGl0eSUyMFZlcmlm
# aWNhdGlvbiUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eSUyMDIwMjAu
# Y3J0MA0GCSqGSIb3DQEBDAUAA4ICAQBfiHbHfm21WhV150x4aPpO4dhEmSUVpbix
# NDmv6TvuIHv1xIs174bNGO/ilWMm+Jx5boAXrJxagRhHQtiFprSjMktTliL4sKZy
# t2i+SXncM23gRezzsoOiBhv14YSd1Klnlkzvgs29XNjT+c8hIfPRe9rvVCMPiH7z
# PZcw5nNjthDQ+zD563I1nUJ6y59TbXWsuyUsqw7wXZoGzZwijWT5oc6GvD3HDokJ
# Y401uhnj3ubBhbkR83RbfMvmzdp3he2bvIUztSOuFzRqrLfEvsPkVHYnvH1wtYyr
# t5vShiKheGpXa2AWpsod4OJyT4/y0dggWi8g/tgbhmQlZqDUf3UqUQsZaLdIu/XS
# jgoZqDjamzCPJtOLi2hBwL+KsCh0Nbwc21f5xvPSwym0Ukr4o5sCcMUcSy6TEP7u
# MV8RX0eH/4JLEpGyae6Ki8JYg5v4fsNGif1OXHJ2IWG+7zyjTDfkmQ1snFOTgyEX
# 8qBpefQbF0fx6URrYiarjmBprwP6ZObwtZXJ23jK3Fg/9uqM3j0P01nzVygTppBa
# bzxPAh/hHhhls6kwo3QLJ6No803jUsZcd4JQxiYHHc+Q/wAMcPUnYKv/q2O444LO
# 1+n6j01z5mggCSlRwD9faBIySAcA9S8h22hIAcRQqIGEjolCK9F6nK9ZyX4lhths
# GHumaABdWzCCB5cwggV/oAMCAQICEzMAAABYZc3rP6HX/NIAAAAAAFgwDQYJKoZI
# hvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjAwHhcNMjUxMDIzMjA0NjU1WhcNMjYxMDIyMjA0NjU1WjCB2zEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOjdBMDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAJ14NKR2kOz1QJZZ/h2WayRXC6Cm3pIVtci/kDQVIBRVLI2SCmqq
# jeKCCbCTN6bNKyTUju53QjUbmQ19loLq9wJO+3l65aAV6mZjumVV3gzUQi5XVuAN
# PzX48ye115HRIY6/NYIVxKUe8wvsG2jTfrD0scywGQXomwxT+18LOcF9GbSLDdWt
# vl6uW71qd5ETMrcLJE47p0YHi2S/7Qadt+yVXUTxQEPY2ESqQqlAaP79cYwS0Qld
# z2pSo5xn29zDeFO41cqonxR0oXJ1uQhEUaAZlGurMoA8xUq/Ht4Pd0zzSxVIr1BN
# Bpi321+XHg9RrdRXGesfyS1QE85OfgVh2zMcCSFZFT06kkjI0OikynXJ6t6R9HOA
# BSaf4Jb3KatFPX82SIyRhr3aYrIZUZe+0ULVIUo8R7wp9ywv8akEMDh0kA7BoejV
# 9g9EX7EshLUwAcgGnvtsNRwckw03JpUzSxLkC3go9YDQXSFo9FjmMg7Y40P/Ik1m
# Onstb2/ah5YyI+R4CJ3U+T/TGJNlYNnu4SlGTQTWwP4bIAbLqGfiF/PVr4xDfWmx
# fdUuDiVbop5irCzvzC255e4pLg9HTeqANGHsMg0J3LNdrDPRzrbu9kAP02ZXn71v
# K/cbTFwGKEJXBo7JPFuFHO3H6lamyD43aHPGcQcy3F3Fcj+KeXMi8L5DAgMBAAGj
# ggHLMIIBxzAdBgNVHQ4EFgQUco1NxXq+FcVyfoYz3ESZ8Z0SCbAwHwYDVR0jBBgw
# FoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcB
# AQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5n
# JTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4IC
# AQB768SIlRdYh3F78ayUwg/HjrWz1Gyvcfi8+9ImHoYfhtFKDjHDH9OEA+rUD03m
# eR4RhE5HJ9K2gyeTaX20QbihB99a8W2Sve6NdikQzSdzbuHj2lCKR/03Fs/Dy1Tg
# hAssEsWxIBBttJMsnRnOOnOfdbV86X5CQ3JI6GK8qWnq3XkC0UB/S2qE2GX3QMzK
# Pg8tDtQ8xSZBeWJ7JgDPJbfa9TbV3RY3WxTAm1eXWruuJldtrNfOgPFJovpdt/fl
# HtHGyUCMpFoSJYYVocUIKJLKh8+5KdhhWQAHskk5iDkDlslzgPCQPEyEicp9yQzo
# Erb+fNz91dEEgC0+iVwwltuhVdtPFRiTM5L9Ettojk2Sf6Gpk6ZPEcw/KFk/KX23
# tav5P28T4l2EW86bPemuWDpKO59FXaOtQziYS/5oZNNWN+PIKur4Rv1U3HRh4daw
# pMDjNOQd+QGWavQLT6X0cyYp6x88xkcfq+nw93HGDDzDF/zcHdoq866Yde9n0HEn
# 9XzML8CIZnx+BliSfpn9RwOrl6ADlQcnJILl75Y/ID4u09hEukVPPkLLH6kzUySo
# 7AYXlilr9luBElXp9i+5Qs+4u/RYQPtJKdMlyZ2MHc1ktKL0yDVCyDZs1cjHElJu
# VrlX/GGd93ALndjqa+jdfkbi2Q2rw744noZSOXR/hhMuejGCB1MwggdPAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABYZc3rP6HX/NIAAAAAAFgwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MDkyMTIwMzIwN1owPwYJKoZIhvcNAQkEMTIEMHOnkB6L07D8
# lJXZiOX0qnOhIEfAvQpxTp3HuoiIxW2YfA/2mzXY+Xzem+SUKf2kXzCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEIMUiVLuyB9D7ACjVxZtbP5Y3r1UF2znyFutq
# f3X1ouhxMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAWGXN6z+h1/zSAAAAAABYMIIDXgYLKoZIhvcN
# AQkQAhIxggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3
# QTAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAJ1keRvbp6twXY7r
# a8J1lR9RK8RcoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7luykDAiGA8yMDI2
# MDkyMTEzNDEzNloYDzIwMjYwOTIyMTM0MTM2WjB0MDoGCisGAQQBhFkKBAExLDAq
# MAoCBQDuW7KQAgEAMAcCAQACAgC7MAcCAQACAhPjMAoCBQDuXQQQAgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
# hqAwDQYJKoZIhvcNAQELBQADggEBAG8Mrl7XO+O3htQlZVd1DY1pNzBrY8gfisbo
# 3BqPTeoR9w1PKfA3Cich4mM5QLBejeSF/rcfvPHDW6gCvX1NojYUqGukFq9mZUTP
# 9g74siXppC0/aUBcMmn/MtnfktkbnRcMm+u5OiRyRipFqpHh0PuBoa0F78BEKq70
# emj6lHsj8ztUPSeW0nhHA7p8vbDKMF9L2TLPyeG76AVVpZQGtoii+hqWHQH7q4Bf
# zn5Xu6h69vKOWb9Jj7MerbNQ9lC8F6YMyOlyHJRNZX+zIFlbZxmcXwP5sCmMKqnD
# jSnnJTFEBZjH5uNCP+WbqFkqB8fq4WJ4MmKB58T6bGJmL8MNnnEwDQYJKoZIhvcN
# AQEBBQAEggIAf4YROFULTQ5rnUbDbuPYeuEjwPdX0x6yIOK9ZS+qp9fQ0SC565o+
# EbVdAcD3PsSsv2sxq/WDzOkEEyVQfSohO7+B/+vTUK0f3BEo9H+Lm3Wsle8DdGuk
# dEu2Prp3JfAO4Q6wljrDZ9lv24xRQ6WNdLDGVSGpbuoks9myzgchqvOaNq/E62aG
# OPlHpacPpFJH/xW8/h7MAchzTP2zBtFJQMzvBJPHDSjw5gs+K2Okysbr9qZ/rbtY
# CXBp0noKKBqEb1K7ERjHOCE3c1969tJObhZyT3yWW/RYMNxqEDDgVFIWclPW/bAp
# qwSEdiPjDXos9OgnUUEZTsKde7kQmDoUe8casQlt2ZNOAw8B9RwTPVsPq9cmwUKh
# zqLMgR1/uNngnVjcBMBgou9UyegcEj4PqaNpY8X5yWx2P+zUhQwDSSznUZ+CgvoE
# grGR9UTmMcnK8NYFhvHe9/EdPriziBwXV1QCwEYUmnVMjNIwtSiHxsd8/WQ51UQQ
# h+xMRgLSvgUuXXZiyxlVCTazTT9WFv+TqyLhHvveNbHMGOSlARnBUNgx+b6ed4GF
# vnTC/Iau07tHuUNnAtLjUXWl+lPkV9AViNkdNNrqVmOKaue8v6/0hP1Ibc1P7elU
# JZfOd2Fso6lqdAFMZ13bGI9Pcj9WmpfX/OWc0Y+GqDQxBNZafq9VuE8=
# SIG # End signature block
