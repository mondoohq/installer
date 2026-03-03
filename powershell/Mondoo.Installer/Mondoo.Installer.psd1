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
# MII+AgYJKoZIhvcNAQcCoII98zCCPe8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggbmMIIEzqADAgECAhMzAAeb324s
# szkfQAfJAAAAB5vfMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDEwHhcNMjYwMjA5MDQyMzAwWhcNMjYwMjEy
# MDQyMzAwWjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAkmiQ
# fNaJaVZNjthDcKV38YNGwudhmmrEa9VuMm67MzCtmKMc8nyvF0VqobrWKeuXRBbQ
# hLe9Qv27p69fWHuDiYK6sXsk4gqXZzTPOka8spDt99jJjrnc+DI9ny+uV+CVNxQr
# Q8SsB9h9ovL9FHuOT3mf504DBcThWXgx5fBhzIYzpQI3yDNvfLTpCsiw4fDB6FGH
# cR3Of5g4wpYYYFnP1McCxbnetJVGz92QGTDyHRWnat2vpZj+wWTQuTUPLYIHJmla
# +0hzkeVfum/UqiE8Cqsi2ccEcwgq/tWYxJv7uGxU0KCCTBFBupD4xyhPa9v+IK7G
# 8it6UXVp51rTmm1j63iB6dparnh9owEzfH8OCxdjhS4WEa4u3CBuOmzbuWd/kk5n
# 91CTnSLbuZVkpNW+4PHMPMobiqGkQAn+Bti4yX/arEG32i9gTTw4CkD6PaBplxC+
# MLuqwyOzLw81bnoqsUETzrNm+mtmbMPTd2wOQhmkCDhdpybT73pzvidCpIeDAgMB
# AAGjggIaMIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUUgBjZZHyIxOyGGD3raUf4OTeHIMwHwYDVR0jBBgw
# FoAU6IPEM9fcnwycdpoKptTfh6ZeWO4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwMS5jcmwwgaUGCCsGAQUFBwEBBIGY
# MIGVMGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENB
# JTIwMDEuY3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQu
# Y29tL29jc3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAiMSxnslVEOe7hWj8
# xw+gdDjWnSvTIYLH1DCWq0SZX4dJTuGvbszwOajbE3OAMV/d0MLwwOQv3OZVkABz
# h+N92/kZueDaOzouRFGVBa04+J1DeVRdTl6f8q1JWfnhokrIgXynLp8OCvpR6oXG
# uU6ta7cdmVXhYQzFX+4lF02nq/mTkY5ycfwQdDCcV980S3CaTVWV6tH2UI56dztj
# BbQdl6snzjpd7XDkQH+SYxG6ylI9Dx3eeMXFlsplMjfl/DRy/JhXlqkYiGhPOz8T
# L65/DsmAEvAs9n/1rkMDsn9GUxbgYOWAdHxYaa5HztKOsaKX/GXQPh0hTSdNxyhW
# gHdHOwjAvMZT5CEOKwnfO6hFl6KCfieXPaweIHhaiLSn7BCcST+rpWbW9/4b+t5q
# EG8bptgniLePfdHEr3NBfaj600xDOCGoxvEJwnMgIv+hSFmkdkLlennv6c/wRx3x
# SQi7KVgZ99ixA0mKm7yXsYxqRjTr//cHWnclSIsnoOXDLLg0L0U9+/NLGNoPhVrg
# aYzehtAwGaKct4N4DRNotzrQvfPxcEfRqObMB9Na1zARVT8j8xCF/dAqRcdJIRKo
# D9CQHS3PsYR8049c925S271dxcru9imgomW5OoUduwLEA6jmdzzozCWVL45lBdWT
# vsRQaNcVVyqhF6T85ohzxfYnCX8wggbmMIIEzqADAgECAhMzAAeb324sszkfQAfJ
# AAAAB5vfMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJp
# ZmllZCBDUyBBT0MgQ0EgMDEwHhcNMjYwMjA5MDQyMzAwWhcNMjYwMjEyMDQyMzAw
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmExDTALBgNV
# BAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMMTW9uZG9v
# LCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAkmiQfNaJaVZN
# jthDcKV38YNGwudhmmrEa9VuMm67MzCtmKMc8nyvF0VqobrWKeuXRBbQhLe9Qv27
# p69fWHuDiYK6sXsk4gqXZzTPOka8spDt99jJjrnc+DI9ny+uV+CVNxQrQ8SsB9h9
# ovL9FHuOT3mf504DBcThWXgx5fBhzIYzpQI3yDNvfLTpCsiw4fDB6FGHcR3Of5g4
# wpYYYFnP1McCxbnetJVGz92QGTDyHRWnat2vpZj+wWTQuTUPLYIHJmla+0hzkeVf
# um/UqiE8Cqsi2ccEcwgq/tWYxJv7uGxU0KCCTBFBupD4xyhPa9v+IK7G8it6UXVp
# 51rTmm1j63iB6dparnh9owEzfH8OCxdjhS4WEa4u3CBuOmzbuWd/kk5n91CTnSLb
# uZVkpNW+4PHMPMobiqGkQAn+Bti4yX/arEG32i9gTTw4CkD6PaBplxC+MLuqwyOz
# Lw81bnoqsUETzrNm+mtmbMPTd2wOQhmkCDhdpybT73pzvidCpIeDAgMBAAGjggIa
# MIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0Bgor
# BgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY/W+D3Nur
# KjAdBgNVHQ4EFgQUUgBjZZHyIxOyGGD3raUf4OTeHIMwHwYDVR0jBBgwFoAU6IPE
# M9fcnwycdpoKptTfh6ZeWO4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmll
# ZCUyMENTJTIwQU9DJTIwQ0ElMjAwMS5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQG
# CCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIwMDEu
# Y3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29j
# c3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAiMSxnslVEOe7hWj8xw+gdDjW
# nSvTIYLH1DCWq0SZX4dJTuGvbszwOajbE3OAMV/d0MLwwOQv3OZVkABzh+N92/kZ
# ueDaOzouRFGVBa04+J1DeVRdTl6f8q1JWfnhokrIgXynLp8OCvpR6oXGuU6ta7cd
# mVXhYQzFX+4lF02nq/mTkY5ycfwQdDCcV980S3CaTVWV6tH2UI56dztjBbQdl6sn
# zjpd7XDkQH+SYxG6ylI9Dx3eeMXFlsplMjfl/DRy/JhXlqkYiGhPOz8TL65/DsmA
# EvAs9n/1rkMDsn9GUxbgYOWAdHxYaa5HztKOsaKX/GXQPh0hTSdNxyhWgHdHOwjA
# vMZT5CEOKwnfO6hFl6KCfieXPaweIHhaiLSn7BCcST+rpWbW9/4b+t5qEG8bptgn
# iLePfdHEr3NBfaj600xDOCGoxvEJwnMgIv+hSFmkdkLlennv6c/wRx3xSQi7KVgZ
# 99ixA0mKm7yXsYxqRjTr//cHWnclSIsnoOXDLLg0L0U9+/NLGNoPhVrgaYzehtAw
# GaKct4N4DRNotzrQvfPxcEfRqObMB9Na1zARVT8j8xCF/dAqRcdJIRKoD9CQHS3P
# sYR8049c925S271dxcru9imgomW5OoUduwLEA6jmdzzozCWVL45lBdWTvsRQaNcV
# VyqhF6T85ohzxfYnCX8wggdaMIIFQqADAgECAhMzAAAABzeMW6HZW4zUAAAAAAAH
# MA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTU0WhcNMjYwNDEzMTcz
# MTU0WjBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAx
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAt/fAAygHxbo+jxA04hNI
# 8bz+EqbWvSu9dRgAawjCZau1Y54IQal5ArpJWi8cIj0WA+mpwix8iTRguq9JELZv
# TMo2Z1U6AtE1Tn3mvq3mywZ9SexVd+rPOTr+uda6GVgwLA80LhRf82AvrSwxmZpC
# H/laT08dn7+Gt0cXYVNKJORm1hSrAjjDQiZ1Jiq/SqiDoHN6PGmT5hXKs22E79Me
# FWYB4y0UlNqW0Z2LPNua8k0rbERdiNS+nTP/xsESZUnrbmyXZaHvcyEKYK85WBz3
# Sr6Et8Vlbdid/pjBpcHI+HytoaUAGE6rSWqmh7/aEZeDDUkz9uMKOGasIgYnenUk
# 5E0b2U//bQqDv3qdhj9UJYWADNYC/3i3ixcW1VELaU+wTqXTxLAFelCi/lRHSjaW
# ipDeE/TbBb0zTCiLnc9nmOjZPKlutMNho91wxo4itcJoIk2bPot9t+AV+UwNaDRI
# bcEaQaBycl9pcYwWmf0bJ4IFn/CmYMVG1ekCBxByyRNkFkHmuMXLX6PMXcveE46j
# Mr9syC3M8JHRddR4zVjd/FxBnS5HOro3pg6StuEPshrp7I/Kk1cTG8yOWl8aqf6O
# JeAVyG4lyJ9V+ZxClYmaU5yvtKYKk1FLBnEBfDWw+UAzQV0vcLp6AVx2Fc8n0vpo
# yudr3SwZmckJuz7R+S79BzMCAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU6IPEM9fcnwycdpoKptTfh6ZeWO4w
# VAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaA
# FNlBKbAPD2Ns72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVy
# aWZpZWQlMjBDb2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEF
# BQcBAQSBoTCBnjBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29u
# ZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQB3/utL
# ItkwLTp4Nfh99vrbpSsL8NwPIj2+TBnZGL3C8etTGYs+HZUxNG+rNeZa+Rzu9oEc
# AZJDiGjEWytzMavD6Bih3nEWFsIW4aGh4gB4n/pRPeeVrK4i1LG7jJ3kPLRhNOHZ
# iLUQtmrF4V6IxtUFjvBnijaZ9oIxsSSQP8iHMjP92pjQrHBFWHGDbkmx+yO6Ian3
# QN3YmbdfewzSvnQmKbkiTibJgcJ1L0TZ7BwmsDvm+0XRsPOfFgnzhLVqZdEyWww1
# 0bflOeBKqkb3SaCNQTz8nshaUZhrxVU5qNgYjaaDQQm+P2SEpBF7RolEC3lllfuL
# 4AOGCtoNdPOWrx9vBZTXAVdTE2r0IDk8+5y1kLGTLKzmNFn6kVCc5BddM7xoDWQ4
# aUoCRXcsBeRhsclk7kVXP+zJGPOXwjUJbnz2Kt9iF/8B6FDO4blGuGrogMpyXkuw
# CC2Z4XcfyMjPDhqZYAPGGTUINMtFbau5RtGG1DOWE9edCahtuPMDgByfPixvhy3s
# n7zUHgIC/YsOTMxVuMQi/bgamemo/VNKZrsZaS0nzmOxKpg9qDefj5fJ9gIHXcp2
# F0OHcVwe3KnEXa8kqzMDfrRl/wwKrNSFn3p7g0b44Ad1ONDmWt61MLQvF54LG62i
# 6ffhTCeoFT9Z9pbUo2gxlyTFg7Bm0fgOlnRfGDCCB54wggWGoAMCAQICEzMAAAAH
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
# ji+tHD6n58vhavFIrmcxghq0MIIasAIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDECEzMAB5vfbiyzOR9AB8kAAAAHm98wDQYJ
# YIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQg0QUzAMpW05B5oWIF2jXLQS+uto5x
# fkque4v8iiMc554wDQYJKoZIhvcNAQEBBQAEggGAIukAUjEXHdQxTC3EjA5juRDI
# CKAqOucyTuKGy/BtjbnNh+HLrUiyn2/3n40fACNdfFi3MWBSndYXL2YZHmCqAFwF
# hWjal+NgAnPSnMp6jaFjvd43gRyCyC6YSWxng8fQAD5unOQjPWrP/7v5QkTfiP7T
# 0471DZJ01CY5YzPJBd2hDKVuzujqjCiUxFGrtf6jpdawOUpavboLV1Xb3Uk+2jYF
# tkeaTZ7VCTfXMbTSTyhKemeCbHWl3A3gm11eM/ubO9+zDU28hb6Q+nX+uFlW9q98
# mjuzDVyRVVmqFZQzV2ihyGf49CCgqd+wWRZblvy4I5FOC30Jf2ZLxlAB0xLfiqZ3
# 1IQ0AfO/knGJCvIKbCpwW/+yOS0NogsLdjepX8Nb8vxcjxElKqXMqFdeX6Ac3ame
# IcqaI2a+dnBRSnvY/0IxsCWE2/jfi/2vaTAWNmCTNwGy1l9tvXKXPUatlpw3bqvt
# ZbXxnTAmYqNf3rqDqHQOv7L7NfveFlN5TH9DOeRxoYIYNDCCGDAGCisGAQQBgjcD
# AwExghggMIIYHAYJKoZIhvcNAQcCoIIYDTCCGAkCAQMxDzANBglghkgBZQMEAgIF
# ADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZCgMBMEEw
# DQYJYIZIAWUDBAICBQAEMPB4lKZVHMfs7KnKWTuNnz9hlrRpSVa7750sxp5iP9oa
# jnSNpCY1EolElmsdENZRKQIGaW9he5OgGBMyMDI2MDIwOTE1MjkyMy45OTFaMASA
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
# WzCCB5cwggV/oAMCAQICEzMAAABWfo+dWAiO6WAAAAAAAFYwDQYJKoZIhvcNAQEM
# BQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENB
# IDIwMjAwHhcNMjUxMDIzMjA0NjUxWhcNMjYxMDIyMjA0NjUxWjCB2zELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
# IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkE1
# MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1l
# IFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBALSln5v7pdNu/3fEZW/DJ/4NEFL7y6mNlbMt7SPFNrRUrKU2aJmTg9wR0/C5
# Efka4TCYG9VYwChTcrGivXC0l4nzxkiAazwoLPT+MtuJayRJq1ekOc+AZqjISD62
# YRL2Z1qQkuBzu42Enov58Zgu/9RK/peS4Nz5ksW/HdiFXAEcUsNQeJsQelyNJ5Hp
# fcGtXWG9sHxqaH62hZsWTsU/XjYbeCx9EQUlbnm2umTaY0v9ILX5u6oiIsj+qej0
# c002zJ1arB51f3f61tMx8fkPkDWecFKipk2SQfYVPOd/tqV+aw3yt9rjWPf1gTgJ
# s26oKRHUJG4jGr1DMlA0oZsnCL4B3UJ0ttO7E4/DPpCS97TnWoT7j6jMLGggoHX8
# MEMdDvUynuxUr2wBGLNQJ5XQpfyhxmQjlb1Dao8i9dCS3tP/hg/f8p6lxlhaVzo2
# rp72f3CkToYzeDOXuscdG9poqnD4ouP4otmYXimpZSRE+wipaRUobN8MoOhf36I0
# MULz521g+DcsepYY1o8JqC3MesNRUgrWrywpct9wS0UpU1OKilMWmvHe2DexKqZ/
# VztEmNLpjryhV61h+68ZfvYmonIrXZ005LAJ0Y73pHSk95YO5UTH5n2VPL1zYjdF
# GCc0/RI6o0ZtLjf4dKF8T4TXz2KnhW8j1xhsc2mFM+s8d6k3AgMBAAGjggHLMIIB
# xzAdBgNVHQ4EFgQUvrYz8rurWf4eRrMi78s9R/hTSFowHwYDVR0jBBgwFoAUa2ko
# OjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNB
# JTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcBAQRtMGsw
# aQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0El
# MjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8G
# CCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
# UmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4ICAQAOA6gF
# xLDtuo/y2uxYJ/0In4rfMbmXpKmee/mHvrB/4UU2xBIxmK2YLKsEf5VFHyghaW2R
# fJrGmT0CTkeGGFBFPF8oy65/GNYwkpqMYfZe7VokqHPyRQcN+eiQJsxhsXgQNhFk
# sUbk69QLmXup2GjfP8LRZIh3LPIDGncVwbOg8VYcruWJ4Sz0JH7pipt5RX7cBO6Y
# nle39ZbJJpYLAugHkhgsxj2VIAr3B+U7/0Hvc+2yCJkg90rs4TiMGj/nikE2H+u0
# 4n8iSpFkEnRn0wOinLuNZPCweqDyvjC5NY28cSucD6i0i+tsYytOEgVxxCUhJ7Bb
# dM8VpMT/5YHo9Q8alJ5q2BHZMb8ykhyAKhVkmbpf+YSPrycbxT4bDUARJOHErpQ5
# CUKXHVYv4Jn/5hxTmIQwY7GtebOC/trAYpd11f0/EYkeukPMWL0y0VsXdnVbKzqA
# sJ7FOFiHogtCYpwr9VixxIe0Ms6/UUq+JCiS1naTWC4YI5KI05hJAIxTu++Ld8Qe
# 3p27yBdBjrFdfcZwlM6vRBisrdIDLmqYSpTYyfmk6Y1jGQxqPhjirJ6fdx5n7Zpd
# EsqdxffjN8vsuliRlGaCGSattu4w44xJ3baVK4fQXT3VSH1SQ/wLvNUc4dOVBwIr
# 6K0NzrPDxCxyIIjnfU1s23YJhs3CC7f3XVUBETGCB1YwggdSAgEBMHgwYTELMAkG
# A1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UE
# AxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMA
# AABWfo+dWAiO6WAAAAAAAFYwDQYJYIZIAWUDBAICBQCgggSvMBEGCyqGSIb3DQEJ
# EAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkF
# MQ8XDTI2MDIwOTE1MjkyM1owPwYJKoZIhvcNAQkEMTIEMGfOAljA7mmwJda+qa0a
# hqhgOjsPboZri6pRdPyHYVRc5m7l+9i5TwIJOZm6FlIYCjCBuQYLKoZIhvcNAQkQ
# Ai8xgakwgaYwgaMwgaAEILYMMyVNpOPwlXeJODleel7gJIfrTXjdn5f2jk0GAwyo
# MHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGlu
# ZyBDQSAyMDIwAhMzAAAAVn6PnVgIjulgAAAAAABWMIIDYQYLKoZIhvcNAQkQAhIx
# ggNQMIIDTKGCA0gwggNEMIICLAIBATCCAQmhgeGkgd4wgdsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNTAwLTA1
# RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFt
# cGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAP9z9ykVKpBZgF5eCDJEnZlu
# 9gQRoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFt
# cGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7TQ91TAiGA8yMDI2MDIwOTEx
# MDQ1M1oYDzIwMjYwMjEwMTEwNDUzWjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDt
# ND3VAgEAMAoCAQACAg9ZAgH/MAcCAQACAh50MAoCBQDtNY9VAgEAMDYGCisGAQQB
# hFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAw
# DQYJKoZIhvcNAQELBQADggEBAEX609f3zLD4A2YDzCxEGMmHpN4VhpeUcqh6dRBR
# Wl/FVoJA2YVtRi4cQl5z1LdKeVt/uBDGUObnbDOZXbJn9fe6nQEc+TjelWNM/A8y
# 5tgXJbA5rAQ82uZqF4t1ZHZ9sTr4LD6emhIb5JEBEtIYptpFnRAkKWUp4wbKwc4f
# vX6EzIMaybM1Jc6xCE0jDkJSKGRGGHBkOBn9MYZUkivwZRBv4Go8f3raHscbReMY
# cLqy7wqKUh43JKYGXwbF+Oc5B3QBkjVu+dEM6KCFD1MdVV+DszktcHL7p6gCyb+h
# EAin30jqpiojRHq4dAVk9IUwRq1W8B7ZINjvVTOhH39ig2MwDQYJKoZIhvcNAQEB
# BQAEggIAnopYuyiEXFNol1bLQQo+5dndHriv7DN9bVggxq+U+aFHlaIOghF3lPyU
# xAiRESRwiZZ7bBWUlnRAoAv058USYcPw+5NZEJfgNSz+Zvf1yEFmDc3TnDS7hwhY
# 3OYhyAWb+XhDLOIH+JrtarCHMlaxQS5pf9xGZPrQt00+rtyxXCLwABsrg3TT3GAG
# iqeAFGtKI2UHgdhQAsC+78BYaxXp+7V2jRF2f7x1UFO+VzCOiyh7AXUV1eDgUIuN
# rQXOCdo2+XoXaHhRp5fy81oIBOui7wfLFwhIPpLFu3UANc6oQ9HR6IVE3O00FEhi
# N1RqwSUKDglPxWdgFOP9Sj+vB6ngdPXBG4MXJCQXOsoBEyduuERaBp6/WO7jDF65
# Sw5bVd5B11yN1+ySkB8Q43D50ZH+7aQKUHfXNuHCdKB8eoJYDdqqDBrGNQboYQcA
# pbCnQcicZjy29AGlJyh2Kv08NkkL+lfVS7+rouNQhWhWUxxXsXMMLFjQ9Z9gvPfT
# 7re20ueOiHAUi3EMztujYiANACZUsQLPPq830TZkwVDUI/RdahGUHATvAjQWQa4g
# Ur4/alQNnBQFLEE4VDKG19B7yjZLy6n+NV5UrTMMsKapq5piDGh1RSyXjV/oomdt
# 4foVhdva9v/wxdVNgYPQvz8nJltdd6EZBEdMHjLHwgM0fpWS8Ks=
# SIG # End signature block
