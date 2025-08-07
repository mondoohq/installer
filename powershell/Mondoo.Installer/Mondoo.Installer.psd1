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
You can use a single command ''Install-Mondoo'' to install cnquery and cnspec packages.'
    
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
# MII9/wYJKoZIhvcNAQcCoII98DCCPewCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBjYqbsakoW33se
# 0s4pRtIINBqkxxLAL1pnI6grKaYCDqCCIqQwggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggbmMIIEzqADAgECAhMzAAS7CvyR
# aI6ucgG3AAAABLsKMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDIwHhcNMjUwODA2MTMwNTAzWhcNMjUwODA5
# MTMwNTAzWjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiA/V
# Tf0F0usY2zRpYuZUeGBIv9BgvqtcYNgvEppiOcDrHMVjMjAlkdt4dDlycKxgJurr
# r2tYIn1RZw9LHK5WbNqby2VoWBpsb18WPO87OvFqGoEuMNbj6NB0sdCczGptUP+X
# gpajklzNYzm7cSUrLPk3se2peGKAQnRJYwI1QGUvb9mm0kj38cV5oyiwGkeMVGJ/
# 6uBK5J/WtliBw1kq6Gxk9T9LOZoYqasbUnSF3kZ/3qxkUTWfexkwZg6gPd/iOoPm
# parZPbX1hak/Wa2vY44RVfj6Jv4DMCPgEsu/mQcJt+PO4b5IbmbUY2kJ1BkMU+7P
# Q6vUEV7Ut3PblQB8YlO9COJvVDEyvY6d6KlxhZPpb2JdssdKTFgvDBP8TdmxMUlO
# es1caKsz0LNRjJAQPPIDRtFW5KwxMt6tWnt6jjZSOEXDepx3I+FgxMgJEddhggye
# zsYm4x69DV2R+imB6P5lg5Av5j1Cu8FmlhlO7AcxDULBPk++GEpIpkyuvsTtAgMB
# AAGjggIaMIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUvFwoMCkqM/YvzDh2rVqEDIJaAt4wHwYDVR0jBBgw
# FoAUJEWZoXeQKnzDyoOwbmQWhCr4LGcwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGY
# MIGVMGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENB
# JTIwMDIuY3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQu
# Y29tL29jc3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAK0CnburAIFNmvyMl
# OnNGK7PtvmyV3uZI3nJVcZCvnZfv8bKYyvXpJGsSgIyhI3k8zrU7DTsxthiWzFBr
# 4fzxmBh07zuyk2xOzt3VGfVVYIUqcUXolCocTKZ3K38wLehhOX52unjk00wUZufZ
# Wy4bWCUv1wYuaX1WTs4EEWs70RBMOyMIi6Jd4NjDIfOkY83+P9e+7tUB9UdRdhvH
# dTYz4g/fbnESvpoHmuk6Dv+IEJtbSvc5+Y+UD4UQxLYElSsFwSGABfotBlLe9N+E
# /+PsBDDUCbDptC2a4XDIXMm/Md3Fq7M5LPtLxSlgNFZxw0OQPo5dDyJOqWrJroJN
# UvMJ9Kdx+up2ymsUtezPZAlSZ8TVzlJJ6nKMMUqDRCGeBZGDA7e3kuX+gSBeh1RJ
# fOhi3PSIpdrmpbjelXEmIqMpwKp8OPOzYspvtBn/Y0+qH+19td0EPpuCe/3YVuCR
# FE7hrnQ78JWPQTmtjoB6HpT0P9hYtjIDFHEL7h6UJ6dfWA1/mXAQSFIEOUhy/DIs
# shmZXvNTVyDEG35fsGoN7z8Q1vcsKxA1TcPKe+MXYSTp/SIlaNl9OuBfjkhK93cm
# h0vWYyBmCZ39lKvbgbp9pVT/Mc1SGSxRdRvGwnxDx+uUUH/PWRmZY1HFPu1L1tj8
# xDhqXAsusBv4KnNDK8zxA2xEmDYwggbmMIIEzqADAgECAhMzAAS7CvyRaI6ucgG3
# AAAABLsKMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJp
# ZmllZCBDUyBBT0MgQ0EgMDIwHhcNMjUwODA2MTMwNTAzWhcNMjUwODA5MTMwNTAz
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmExDTALBgNV
# BAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMMTW9uZG9v
# LCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiA/VTf0F0usY
# 2zRpYuZUeGBIv9BgvqtcYNgvEppiOcDrHMVjMjAlkdt4dDlycKxgJurrr2tYIn1R
# Zw9LHK5WbNqby2VoWBpsb18WPO87OvFqGoEuMNbj6NB0sdCczGptUP+XgpajklzN
# Yzm7cSUrLPk3se2peGKAQnRJYwI1QGUvb9mm0kj38cV5oyiwGkeMVGJ/6uBK5J/W
# tliBw1kq6Gxk9T9LOZoYqasbUnSF3kZ/3qxkUTWfexkwZg6gPd/iOoPmparZPbX1
# hak/Wa2vY44RVfj6Jv4DMCPgEsu/mQcJt+PO4b5IbmbUY2kJ1BkMU+7PQ6vUEV7U
# t3PblQB8YlO9COJvVDEyvY6d6KlxhZPpb2JdssdKTFgvDBP8TdmxMUlOes1caKsz
# 0LNRjJAQPPIDRtFW5KwxMt6tWnt6jjZSOEXDepx3I+FgxMgJEddhggyezsYm4x69
# DV2R+imB6P5lg5Av5j1Cu8FmlhlO7AcxDULBPk++GEpIpkyuvsTtAgMBAAGjggIa
# MIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0Bgor
# BgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY/W+D3Nur
# KjAdBgNVHQ4EFgQUvFwoMCkqM/YvzDh2rVqEDIJaAt4wHwYDVR0jBBgwFoAUJEWZ
# oXeQKnzDyoOwbmQWhCr4LGcwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmll
# ZCUyMENTJTIwQU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQG
# CCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIwMDIu
# Y3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29j
# c3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAK0CnburAIFNmvyMlOnNGK7Pt
# vmyV3uZI3nJVcZCvnZfv8bKYyvXpJGsSgIyhI3k8zrU7DTsxthiWzFBr4fzxmBh0
# 7zuyk2xOzt3VGfVVYIUqcUXolCocTKZ3K38wLehhOX52unjk00wUZufZWy4bWCUv
# 1wYuaX1WTs4EEWs70RBMOyMIi6Jd4NjDIfOkY83+P9e+7tUB9UdRdhvHdTYz4g/f
# bnESvpoHmuk6Dv+IEJtbSvc5+Y+UD4UQxLYElSsFwSGABfotBlLe9N+E/+PsBDDU
# CbDptC2a4XDIXMm/Md3Fq7M5LPtLxSlgNFZxw0OQPo5dDyJOqWrJroJNUvMJ9Kdx
# +up2ymsUtezPZAlSZ8TVzlJJ6nKMMUqDRCGeBZGDA7e3kuX+gSBeh1RJfOhi3PSI
# pdrmpbjelXEmIqMpwKp8OPOzYspvtBn/Y0+qH+19td0EPpuCe/3YVuCRFE7hrnQ7
# 8JWPQTmtjoB6HpT0P9hYtjIDFHEL7h6UJ6dfWA1/mXAQSFIEOUhy/DIsshmZXvNT
# VyDEG35fsGoN7z8Q1vcsKxA1TcPKe+MXYSTp/SIlaNl9OuBfjkhK93cmh0vWYyBm
# CZ39lKvbgbp9pVT/Mc1SGSxRdRvGwnxDx+uUUH/PWRmZY1HFPu1L1tj8xDhqXAsu
# sBv4KnNDK8zxA2xEmDYwggdaMIIFQqADAgECAhMzAAAABJZQS9Lb7suIAAAAAAAE
# MA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTUyWhcNMjYwNDEzMTcz
# MTUyWjBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAy
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA4c6g6DOiY6bAOwCPbBlQ
# F2tjo3ckUZuab5ZorMnRp4rOmwZDiTbIpzFkZ/k8k4ivBJV1w5/b/oykI+eXAqaa
# xMdyAO0ModnEW7InfQ+rTkykEzHxRbCNg6KDsTnYc/YdL7IIiJli8k51upaHLL7C
# Ym9YNc0SFYvlaFj2O0HjO9y/NRmcWNjamZOlRjxW2cWgUsUdazSHgRCek87V2bM/
# 17b+o8WXUW91IpggRasmiZ65WEFHXKbyhm2LbhBK6ZWmQoFeE+GWrKWCGK/q/4Ri
# TaMNhHXWvWv+//I58UtOxVi3DaK1fQ6YLyIIGHzD4CmtcrGivxupq/crrHunGNB7
# //Qmul2ZP9HcOmY/aptgUnwT+20g/A37iDfuuVw6yS2Lo0/kp/jb+J8vE4FMqIiw
# xGByL482PMVBC3qd/NbFQa8Mmj6ensU+HEqv9ar+AbcKwumbZqJJKmQrGaSNdWfk
# 2NodgcWOmq7jyhbxwZOjnLj0/bwnsUNcNAe09v+qiozyQQes8A3UXPcRQb8G+c0y
# aO2ICifWTK7ySuyUJ88k1mtN22CNftbjitiAeafoZ9Vmhn5Rfb+S/K5arVvTcLuk
# t5PdTDQxl557EIE6A+6XFBpdsjOzkLzdEh7ELk8PVPMjQfPCgKtJ84c17fd2C9+p
# xF1lEQUFXY/YtCL+Nms9cWUCAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUJEWZoXeQKnzDyoOwbmQWhCr4LGcw
# VAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaA
# FNlBKbAPD2Ns72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVy
# aWZpZWQlMjBDb2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEF
# BQcBAQSBoTCBnjBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29u
# ZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQBnLThd
# lbMNIokdKtzSa8io+pEO95Cc3VOyY/hQsIIcdMyk2hJOzLt/M1WXfQyElDk/QtyL
# zX63TdOb5J+nO8t0pzzwi7ZYvMiNqKvAQO50sMOJn3T3hCPppxNNhoGFVxz2UyiQ
# 4b2vOrcsLK9TOEFXWbUMJObR9PM0wZsABIhu4k6VVLxEDe0GSeQX/ZE7PHfTg44L
# uft4IKqYmnv1Cuosp3glFYsVegLnMWZUZ8UtO9F8QCiAouJYhL5OlCksgDb9ve/H
# QhLFnelfg6dQubIFsqB9IlConYKJZ/HaMZvYtA7y9EORK4cxlvTetCXAHayiSXH0
# ueE/T92wVG0csv5VdUyj6yVrm22vlKYAkXINKvDOB8+s4h+TgShlUa2ACu2FWn7J
# zlTSbpk0IE8REuYmkuyE/BTkk93WDMx7PwLnn4J+5fkvbjjQ08OewfpMhh8SuPdQ
# KqmZ40I4W2UyJKMMTbet16JFimSqDChgnCB6lwlpe0gfbo97U7prpbfBKp6B2k2f
# 7Y+TjWrQYN+OdcPOyQAdxGGPBwJSaJG3ohdklCxgAJ5anCxeYl7SjQ5Eua6atjIe
# VhN0KfPLFPpYz5CQU+JC2H79x4d/O6YOFR9aYe54/CGup7dRUIfLSv1/j0DPc6El
# f3YyWxloWj8yeY3kHrZFaAlRMwhAXyPQ3rEX9zCCB54wggWGoAMCAQICEzMAAAAH
# h6M0o3uljhwAAAAAAAcwDQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0
# IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0
# eSAyMDIwMB4XDTIxMDQwMTIwMDUyMFoXDTM2MDQwMTIwMTUyMFowYzELMAkGA1UE
# BhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMr
# TWljcm9zb2Z0IElEIFZlcmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALLwwK8ZiCji3VR6TElsaQhVCbRS
# /3pK+MHrJSj3Zxd3KU3rlfL3qrZilYKJNqztA9OQacr1AwoNcHbKBLbsQAhBnIB3
# 4zxf52bDpIO3NJlfIaTE/xrweLoQ71lzCHkD7A4As1Bs076Iu+mA6cQzsYYH/Cbl
# 1icwQ6C65rU4V9NQhNUwgrx9rGQ//h890Q8JdjLLw0nV+ayQ2Fbkd242o9kH82RZ
# sH3HEyqjAB5a8+Ae2nPIPc8sZU6ZE7iRrRZywRmrKDp5+TcmJX9MRff241UaOBs4
# NmHOyke8oU1TYrkxh+YeHgfWo5tTgkoSMoayqoDpHOLJs+qG8Tvh8SnifW2Jj3+i
# i11TS8/FGngEaNAWrbyfNrC69oKpRQXY9bGH6jn9NEJv9weFxhTwyvx9OJLXmRGb
# AUXN1U9nf4lXezky6Uh/cgjkVd6CGUAf0K+Jw+GE/5VpIVbcNr9rNE50Sbmy/4RT
# CEGvOq3GhjITbCa4crCzTTHgYYjHs1NbOc6brH+eKpWLtr+bGecy9CrwQyx7S/Bf
# YJ+ozst7+yZtG2wR461uckFu0t+gCwLdN0A6cFtSRtR8bvxVFyWwTtgMMFRuBa3v
# mUOTnfKLsLefRaQcVTgRnzeLzdpt32cdYKp+dhr2ogc+qM6K4CBI5/j4VFyC4QFe
# UP2YAidLtvpXRRo3AgMBAAGjggI1MIICMTAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYB
# BAGCNxUBBAMCAQAwHQYDVR0OBBYEFNlBKbAPD2Ns72nX9c0pnqRIajDmMFQGA1Ud
# IARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wGQYJKwYBBAGCNxQCBAwe
# CgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSob
# yhmYBAcnz1AQT2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJp
# ZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIw
# LmNybDCBwwYIKwYBBQUHAQEEgbYwgbMwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5
# JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5
# JTIwMjAyMC5jcnQwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1pY3Jvc29m
# dC5jb20vb2NzcDANBgkqhkiG9w0BAQwFAAOCAgEAfyUqnv7Uq+rdZgrbVyNMul5s
# kONbhls5fccPlmIbzi+OwVdPQ4H55v7VOInnmezQEeW4LqK0wja+fBznANbXLB0K
# rdMCbHQpbLvG6UA/Xv2pfpVIE1CRFfNF4XKO8XYEa3oW8oVH+KZHgIQRIwAbyFKQ
# 9iyj4aOWeAzwk+f9E5StNp5T8FG7/VEURIVWArbAzPt9ThVN3w1fAZkF7+YU9kbq
# 1bCR2YD+MtunSQ1Rft6XG7b4e0ejRA7mB2IoX5hNh3UEauY0byxNRG+fT2MCEhQl
# 9g2i2fs6VOG19CNep7SquKaBjhWmirYyANb0RJSLWjinMLXNOAga10n8i9jqeprz
# SMU5ODmrMCJE12xS/NWShg/tuLjAsKP6SzYZ+1Ry358ZTFcx0FS/mx2vSoU8s8HR
# vy+rnXqyUJ9HBqS0DErVLjQwK8VtsBdekBmdTbQVoCgPCqr+PDPB3xajYnzevs7e
# idBsM71PINK2BoE2UfMwxCCX3mccFgx6UsQeRSdVVVNSyALQe6PT12418xon2iDG
# E81OGCreLzDcMAZnrUAx4XQLUz6ZTl65yPUiOh3k7Yww94lDf+8oG2oZmDh5O1Qe
# 38E+M3vhKwmzIeoB1dVLlz4i3IpaDcR+iuGjH2TdaC1ZOmBXiCRKJLj4DT2uhJ04
# ji+tHD6n58vhavFIrmcxghqxMIIarQIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDICEzMABLsK/JFojq5yAbcAAAAEuwowDQYJ
# YIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQg0QUzAMpW05B5oWIF2jXLQS+uto5x
# fkque4v8iiMc554wDQYJKoZIhvcNAQEBBQAEggGAfH1pKQ0SDgRNA5UwB+o2+n6h
# NuesP2flbzOHeElefPfl8aCEjF7ZbzKbhwVZ9j0kUnooVllksuILNXpvEC5vmwmw
# AlJhYtT8mxA6TFWsYezi2VCbPlL+lfy4uQbP28LphZHH9j5feggTAIscH+cdJGWj
# hhFu+uMXPm7iYr1GzG6AadHdvFsnEfce/TNarpVpmjpsb8ldhiQUXfCBH4mfvB+j
# IQEc7EFhq3QPcGcnfF3gcpXdIB8OeN9fUdbytqFxmpz9F3eSPM6s5iXGsYScbb/k
# 6I256/90CtVfCZ5+bQvtzz3Aq1hTN8tLFC8VmuWw0teKXh/0E0CiyoyAcDDtz8oC
# Ntm/DyoLk4gPa/orAynEIDQZ5b6RTXtneH/pJxZ42zTbtUI8ObsAipgzOXr5/JXg
# mZMAImk9hl7p86BPdH/3EtJi2fwMp7IKgY+5xdJB1eomtuggYl5+zKNYtCv/FpaC
# XGnKRnm0JC1XwfD96So53GtUQQM36qldcKc7FBaCoYIYMTCCGC0GCisGAQQBgjcD
# AwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgBZQMEAgIF
# ADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZCgMBMEEw
# DQYJYIZIAWUDBAICBQAEMBkmk36cGJ5U9QZiXq6vfLGyQP1xMdU2ZXv2g9bikv8w
# 2XrVmOsPlgLqosECifNJEQIGaFl186MQGBMyMDI1MDgwNzA5NDc1MC40NTNaMASA
# AgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQL
# Ex5uU2hpZWxkIFRTUyBFU046QTUwMC0wNUUwLUQ5NDcxNTAzBgNVBAMTLE1pY3Jv
# c29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5oIIPITCCB4Iw
# ggVqoAMCAQICEzMAAAAF5c8P/2YuyYcAAAAAAAUwDQYJKoZIhvcNAQEMBQAwdzEL
# MAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYG
# A1UEAxM/TWljcm9zb2Z0IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290IENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAyMDIwMB4XDTIwMTExOTIwMzIzMVoXDTM1MTExOTIw
# NDIzMVowYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5n
# IENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCefOdSY/3g
# xZ8FfWO1BiKjHB7X55cz0RMFvWVGR3eRwV1wb3+yq0OXDEqhUhxqoNv6iYWKjkMc
# LhEFxvJAeNcLAyT+XdM5i2CgGPGcb95WJLiw7HzLiBKrxmDj1EQB/mG5eEiRBEp7
# dDGzxKCnTYocDOcRr9KxqHydajmEkzXHOeRGwU+7qt8Md5l4bVZrXAhK+WSk5Cih
# NQsWbzT1nRliVDwunuLkX1hyIWXIArCfrKM3+RHh+Sq5RZ8aYyik2r8HxT+l2hmR
# llBvE2Wok6IEaAJanHr24qoqFM9WLeBUSudz+qL51HwDYyIDPSQ3SeHtKog0ZubD
# k4hELQSxnfVYXdTGncaBnB60QrEuazvcob9n4yR65pUNBCF5qeA4QwYnilBkfnme
# AjRN3LVuLr0g0FXkqfYdUmj1fFFhH8k8YBozrEaXnsSL3kdTD01X+4LfIWOuFzTz
# uoslBrBILfHNj8RfOxPgjuwNvE6YzauXi4orp4Sm6tF245DaFOSYbWFK5ZgG6cUY
# 2/bUq3g3bQAqZt65KcaewEJ3ZyNEobv35Nf6xN6FrA6jF9447+NHvCjeWLCQZ3M8
# lgeCcnnhTFtyQX3XgCoc6IRXvFOcPVrr3D9RPHCMS6Ckg8wggTrtIVnY8yjbvGOU
# sAdZbeXUIQAWMs0d3cRDv09SvwVRd61evQIDAQABo4ICGzCCAhcwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRraSg6NS9IY0DPe9iv
# Sek+2T3bITBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMA8G
# A1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUyH7SaoUqG8oZmAQHJ89QEE9oqKIw
# gYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9v
# dCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5jcmwwgZQGCCsGAQUF
# BwEBBIGHMIGEMIGBBggrBgEFBQcwAoZ1aHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJZGVudGl0eSUyMFZlcmlmaWNhdGlv
# biUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eSUyMDIwMjAuY3J0MA0G
# CSqGSIb3DQEBDAUAA4ICAQBfiHbHfm21WhV150x4aPpO4dhEmSUVpbixNDmv6Tvu
# IHv1xIs174bNGO/ilWMm+Jx5boAXrJxagRhHQtiFprSjMktTliL4sKZyt2i+SXnc
# M23gRezzsoOiBhv14YSd1Klnlkzvgs29XNjT+c8hIfPRe9rvVCMPiH7zPZcw5nNj
# thDQ+zD563I1nUJ6y59TbXWsuyUsqw7wXZoGzZwijWT5oc6GvD3HDokJY401uhnj
# 3ubBhbkR83RbfMvmzdp3he2bvIUztSOuFzRqrLfEvsPkVHYnvH1wtYyrt5vShiKh
# eGpXa2AWpsod4OJyT4/y0dggWi8g/tgbhmQlZqDUf3UqUQsZaLdIu/XSjgoZqDja
# mzCPJtOLi2hBwL+KsCh0Nbwc21f5xvPSwym0Ukr4o5sCcMUcSy6TEP7uMV8RX0eH
# /4JLEpGyae6Ki8JYg5v4fsNGif1OXHJ2IWG+7zyjTDfkmQ1snFOTgyEX8qBpefQb
# F0fx6URrYiarjmBprwP6ZObwtZXJ23jK3Fg/9uqM3j0P01nzVygTppBabzxPAh/h
# Hhhls6kwo3QLJ6No803jUsZcd4JQxiYHHc+Q/wAMcPUnYKv/q2O444LO1+n6j01z
# 5mggCSlRwD9faBIySAcA9S8h22hIAcRQqIGEjolCK9F6nK9ZyX4lhthsGHumaABd
# WzCCB5cwggV/oAMCAQICEzMAAABIVXdyHnSSt/cAAAAAAEgwDQYJKoZIhvcNAQEM
# BQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENB
# IDIwMjAwHhcNMjQxMTI2MTg0ODUyWhcNMjUxMTE5MTg0ODUyWjCB2zELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
# IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkE1
# MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1l
# IFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAMt+gPdn75JVMhgkWcWc+tWUy9oliU9OuicMd7RW6IcA2cIpMiryomTjB5n5
# x/X68gntx2X7+DDcBpGABBP+INTq8s3pB8WDVgA7pxHu+ijbLhAMk+C4aMqka043
# EaP185q8CQNMfiBpMme4r2aG8jNSojtMQNXsmgrpLLSRixVxZunaYXhEngWWKoSb
# vRg1LAuOcqfmpghkmhBgqD1lZjNhpuCv1yUeyOVm0V6mxNifaGuKby9p4713KZ+T
# umZetBfY7zlRCXyToArYHwopBW402cFrfsQBZ/HGqU73tY6+TNug1lhYdYU6VLdq
# SW9Jr7vjY9JUjISCtoKCSogxmRW7MX7lCe7JV6Rdpn+HP7e6ObKvGyddRdtdiZCL
# p6dPtyiZYalN9GjZZm360TO+GXjpiZD0gZER+f5lEFavwIcD7HarW6qD0ZN81S+R
# DgfEtJ67h6oMUqP1WIiFC75if8gaK1aO5+Z8EqnaeKALgUVptF7i9KGsDvEm2ts4
# WYneMAhG2+7Z25+IjtW4ZAI83ZtdGOJp9sFd68S6EDf33wQLPi7CcZ9IUXW74tLv
# INktvw3PFee6I3hs/9fDcCMoEIav+WeZImILCgwRGFcLItvwpSEA7NcXToRk3TGf
# C53YD3g5NDujrqhduKLbVnorGOdIZXVeLMk0Jr4/XIUQGpUpAgMBAAGjggHLMIIB
# xzAdBgNVHQ4EFgQUpr139LrrfUoZ97y6Zho7Nzwc90cwHwYDVR0jBBgwFoAUa2ko
# OjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNB
# JTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcBAQRtMGsw
# aQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0El
# MjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8G
# CCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
# UmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4ICAQBNrYvg
# HjRMA0wxiAI1dPL5y4pOMPM1nd0An5Lg9sAp/vwUHBDv2FiKGpn+oiDoZa3+NDkY
# CwFKkFgo1k4y1QwCs1B8iVnjbLa3KUA//EEZDrDCa7S4GZfODpbdOiZNnnpuH3SW
# Ltk7gFuKIKDYICSm+1O+uBi7sVu+9OpMi/8u9dBoInH6zG8k+xsgDJZRJ8hhN0Ba
# VWjrewnwCQfmnOmJ++QvJeYvGraNPLBp4P+kprMQnBcBvLz67TigIZUJkNsP6wM4
# nvneFuXpfJY5eYKldW+PbA+hcl0j5PoM+1z0Za0zFINQpm1UlXZRWAAJrPHyA4OJ
# 2PqHdobA6vxS38Ww79fzndDUJil8dZ9bckSQtzcWyUp/YqXbMfXgQGgt5SlPKSGf
# w1lR5eEey64qM/HyZQAtb8uCVSNlfInfIFDU+I56+nFOi3xp9dzquWr0UnaSC0zq
# KPa5bt/1q3nIhx3AUz1VSbRoKCJe+O9GRB5JQggCbjQtfaq97aR0+A179m3zJvnM
# NywmMeFk+1eJbdOcFRguoKwucPp9WHpflC8Vu2MuUEgy3deW8BCe5UTOGjK3eKzD
# D3Dy36gYKDho2H3gh0q9Q1LV9/EL5D5euxPfAOVKWo1It+ijGGwK7mBcq3Ol+HHz
# 7iX2tUcnGBkT2fAYqIBvA1fEoUHdtWCbCh0ltTGCB1MwggdPAgEBMHgwYTELMAkG
# A1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UE
# AxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMA
# AABIVXdyHnSSt/cAAAAAAEgwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqGSIb3DQEJ
# EAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkF
# MQ8XDTI1MDgwNzA5NDc1MFowPwYJKoZIhvcNAQkEMTIEMIKDTCOZFEV/Rfa8J61v
# JsLKbswNIddguPn4hw+n0rp22dRCEjFOU+9RLtHEmM2LeTCBuQYLKoZIhvcNAQkQ
# Ai8xgakwgaYwgaMwgaAEIOoqAVebTwjWn0P0gLwZ03YfjX3QvDtHZEl38m8i8x1B
# MHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGlu
# ZyBDQSAyMDIwAhMzAAAASFV3ch50krf3AAAAAABIMIIDXgYLKoZIhvcNAQkQAhIx
# ggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNTAwLTA1
# RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFt
# cGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAOYSfUGUVzjpxDh59/qJiDRZ
# aMMnoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFt
# cGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7D6ebjAiGA8yMDI1MDgwNzAz
# MzkyNloYDzIwMjUwODA4MDMzOTI2WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDs
# Pp5uAgEAMAcCAQACAjAxMAcCAQACAhMYMAoCBQDsP+/uAgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBAARq0UcnGQBv7RNutcBg5HMjh+DGuka/K+xbmRmhpLv3
# 822hFrK9KmPUdOHYSCkVguqKqlzj0lSFGrvATi159g+dp61lTO/m5bTiUV9NBziD
# F4oG/uRNHFRHy8oXELv/4H6t+VvCWUVEkH8Xif0gtEnJEOm+AQMKcjRTYKGHAkVQ
# ldQk0IqqIQqTv7vUzBNyabtP5jLRqYWGwfbHyVqg7t4WhrpNRKpqwjISSWTic5Oe
# aENAPtljiA8QGZqyfG7rZrvYNIUGiHw++JMlJ43YPBRvefUhPKjMvzxntPSmLUlj
# 00I6CH71o7uwGhLy0OYRxW8mf6AGGQ/W5ekT8qqUcNkwDQYJKoZIhvcNAQEBBQAE
# ggIAaSsucBwXswHryEJz/jvIQhZBR+ueZzFiMGPQIV5tTH7Aqv40KmocYBIZRzyn
# FTOGXdXqI2NpEqUEjLompqeSeRA1AXH7zNUKaRM3qP57bLl+2gNFhAs9FHtjJ/fL
# zDAEC5NpU259xGoqtSY84Ym9OM9+UjIFwXjGenGgLMfSpr5bzMug880y/dS1fbSK
# NXPQ1pNnTKfB4wOkcAQfRB0qzoJnlIZ04hAIQ3jCaFZ9xDI2PUx3CQb7SHJu4fDO
# KshI6+jDUMzPUmQGnYj9UzCq84B8gKxeOQg1E/xR9FnkQfp97ysL0GDMJ0D/73Pz
# jyUpPhPYFIIl8xs/0cJfvrFpDUX3uYUhXeN0uEmb548KFocu0bAdkmyzSGB5ADWC
# 0bYUx9pwEdSgmSNVw9SsxdyeKX67y5/sUSRaxadWblCuOBPmSLdvd38tj5Dc1oTW
# Lp2UE0QnG+S7jUVZ7Rn9sYrVLuVbajTkYVwnbXQr9EuBXhdBkftajaG3VgKUb6AP
# 1beZoPYGUjngwMdB6YouC/MyMEdwR+VLshlzkSbM2hPTNQ7s8yhf9ly1Y/gUYXOS
# nlNy6qijn4ikasXBphYH1Wpe4COmWPTFC6YVIluqxKUSfYUpl48f7pZS5qgkseP8
# 6qUkDXCek+dx5t6gy5KuLugIv9npOG11ieQAb6zAJsmHnuY=
# SIG # End signature block
