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
# MII9/wYJKoZIhvcNAQcCoII98DCCPewCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDIWQWnFK/iLLgx
# lqcZgYdbPXD+zc4t94QeJhwug65R+qCCIqQwggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggbmMIIEzqADAgECAhMzAAdbPKux
# V+LY3kBUAAAAB1s8MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDIwHhcNMjYwMzEwMDM0NjQ4WhcNMjYwMzEz
# MDM0NjQ4WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiup0
# V1a1VYgyjr+DmhU2hvjaNkoGPn1oyVyOeHsb9bFSLNW99SeVHlHt4ZQ56NQeyGVs
# M2r56Y+q7ZOUQABFXehQVJOIctREvYlxTdOo4tY0IXhHCRxTULeDxxfpI0hCIm8O
# TZJjCGKdXNbZl9R2cUjXZJjvGHvBr5iCawni2nHkeMc0Jb0+75FKwW5mu+uOMqC/
# 0E86A24Nui1Ivgc2LUyBDOcOmbNkhuUHOkHO5mucyrg42offr1ybYtLIf57ZveUm
# m47JcyKxv5lCFEckDscgbCX6t5c8YW3jmutRJ7x5ArsBNGxlGRRB4arQgK8p85Fi
# 3QjUSkCDGiXZ48DU0stQCVZM0JV8PstUIj9MiNnppNK7IFYofhCSAsJjKWvPnEYO
# ykO6vsguqHBJfYGxDQ/YB7KHgTRLUGZoUkwXEhElSqPtfXv5ng0e5f/2XphYxatX
# fj2JrF4b6yEvFPA47X7fHT4i0kQIPiAuuYhJtYn8BMNiogNx1M4GRihXG0L1AgMB
# AAGjggIaMIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUWI2wGKeqjdWeRtbjq9jW0skn/kYwHwYDVR0jBBgw
# FoAUZZ9RzoVofy+KRYiq3acxux4NAF4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGY
# MIGVMGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENB
# JTIwMDIuY3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQu
# Y29tL29jc3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAQagqhhLuyYFSZVJp
# NPKNiSOnmscIXimdt8kcK7pySu6ImeJkgglKn51sYOu6Axox2hmga+Ty5D/2UtZC
# 7SdG5VsIb59T0KKQUGkYuT1gFbahHT8fw+18zHA89FINgWlvNbAARQGmHYa+O457
# bPpOIye6vUtZuhlALwCyGv+ztpoR11CVdITqouy/64p6OVZioJVi3YbKyeonVuTa
# gfazyX/N4s17Wm/yrLnr9B7atTha5xoDAzZH4hUgFGvQv+Dn5N5tQ6EaiiT8ycwk
# X3DnJ10/5VugyKo7E+aaL/qLyrnBWxjFw0Qdi2c7ckHnhp6WUxrjJlvE6LgChupr
# FCGlRsTGcBlQHQECSGLV2T9Y/ltWb0Wa8n7goEOlk7zWXLKsYU0odm1+a2c2kv18
# Muasr8nV5lw08laPQuxe9INxHWGz2O3AQUuWLR8V25YeoAPvVzT4j//jrY5hIlq8
# 9sRJQlG3AnKGGNnj2rAVSrQy+Xsv2y6YaxLCSYVwuzNGvQTIHfGapoCo380ZGKDI
# gQzItyC2gROzVcqeKnvo4UAkwJA/4byrsl+ikiHj43WzZJ3+RTCk+Tq4DJjr6Z8M
# AclYvNRuIyySs6Fv1DjOPHL0Li2ywzn/4kaC+u/rT7inYK6X4HU9m7EzAQDkHoox
# BBNIuLxAi/ybJ3C1drTlGVQMSwcwggbmMIIEzqADAgECAhMzAAdbPKuxV+LY3kBU
# AAAAB1s8MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJp
# ZmllZCBDUyBFT0MgQ0EgMDIwHhcNMjYwMzEwMDM0NjQ4WhcNMjYwMzEzMDM0NjQ4
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmExDTALBgNV
# BAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMMTW9uZG9v
# LCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiup0V1a1VYgy
# jr+DmhU2hvjaNkoGPn1oyVyOeHsb9bFSLNW99SeVHlHt4ZQ56NQeyGVsM2r56Y+q
# 7ZOUQABFXehQVJOIctREvYlxTdOo4tY0IXhHCRxTULeDxxfpI0hCIm8OTZJjCGKd
# XNbZl9R2cUjXZJjvGHvBr5iCawni2nHkeMc0Jb0+75FKwW5mu+uOMqC/0E86A24N
# ui1Ivgc2LUyBDOcOmbNkhuUHOkHO5mucyrg42offr1ybYtLIf57ZveUmm47JcyKx
# v5lCFEckDscgbCX6t5c8YW3jmutRJ7x5ArsBNGxlGRRB4arQgK8p85Fi3QjUSkCD
# GiXZ48DU0stQCVZM0JV8PstUIj9MiNnppNK7IFYofhCSAsJjKWvPnEYOykO6vsgu
# qHBJfYGxDQ/YB7KHgTRLUGZoUkwXEhElSqPtfXv5ng0e5f/2XphYxatXfj2JrF4b
# 6yEvFPA47X7fHT4i0kQIPiAuuYhJtYn8BMNiogNx1M4GRihXG0L1AgMBAAGjggIa
# MIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0Bgor
# BgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY/W+D3Nur
# KjAdBgNVHQ4EFgQUWI2wGKeqjdWeRtbjq9jW0skn/kYwHwYDVR0jBBgwFoAUZZ9R
# zoVofy+KRYiq3acxux4NAF4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmll
# ZCUyMENTJTIwRU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQG
# CCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIwMDIu
# Y3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29j
# c3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAQagqhhLuyYFSZVJpNPKNiSOn
# mscIXimdt8kcK7pySu6ImeJkgglKn51sYOu6Axox2hmga+Ty5D/2UtZC7SdG5VsI
# b59T0KKQUGkYuT1gFbahHT8fw+18zHA89FINgWlvNbAARQGmHYa+O457bPpOIye6
# vUtZuhlALwCyGv+ztpoR11CVdITqouy/64p6OVZioJVi3YbKyeonVuTagfazyX/N
# 4s17Wm/yrLnr9B7atTha5xoDAzZH4hUgFGvQv+Dn5N5tQ6EaiiT8ycwkX3DnJ10/
# 5VugyKo7E+aaL/qLyrnBWxjFw0Qdi2c7ckHnhp6WUxrjJlvE6LgChuprFCGlRsTG
# cBlQHQECSGLV2T9Y/ltWb0Wa8n7goEOlk7zWXLKsYU0odm1+a2c2kv18Muasr8nV
# 5lw08laPQuxe9INxHWGz2O3AQUuWLR8V25YeoAPvVzT4j//jrY5hIlq89sRJQlG3
# AnKGGNnj2rAVSrQy+Xsv2y6YaxLCSYVwuzNGvQTIHfGapoCo380ZGKDIgQzItyC2
# gROzVcqeKnvo4UAkwJA/4byrsl+ikiHj43WzZJ3+RTCk+Tq4DJjr6Z8MAclYvNRu
# IyySs6Fv1DjOPHL0Li2ywzn/4kaC+u/rT7inYK6X4HU9m7EzAQDkHooxBBNIuLxA
# i/ybJ3C1drTlGVQMSwcwggdaMIIFQqADAgECAhMzAAAABft6XDITYd9dAAAAAAAF
# MA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTUzWhcNMjYwNDEzMTcz
# MTUzWjBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDAy
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0hqZfD8ykKTA6CDbWvsh
# mBpDoBf7Lv132RVuSqVwQO3aALLkuRnnTIoRmMGo0fIMQrtwR6UHB06xdqOkAfqB
# 6exubXTHu44+duHUCdE4ngjELBQyluMuSOnHaEdveIbt31OhMEX/4nQkph4+Ah0e
# R4H2sTRrVKmKrlOoQlhia73Qg2dHoitcX1uT1vW3Knpt9Mt76H7ZHbLNspMZLkWB
# abKMl6BdaWZXYpPGdS+qY80gDaNCvFq0d10UMu7xHesIqXpTDT3Q3AeOxSylSTc/
# 74P3og9j3OuemEFauFzL55t1MvpadEhQmD8uFMxFv/iZOjwvcdY1zhanVLLyplz1
# 3/NzSoU3QjhPdqAGhRIwh/YDzo3jCdVJgWQRrW83P3qWFFkxNiME2iO4IuYgj7Rw
# seGwv7I9cxOyaHihKMdT9NeoSjpSNzVnKKGcYMtOdMtKFqoV7Cim2m84GmIYZTBo
# rR/Po9iwlasTYKFpGZqdWKyYnJO2FV8oMmWkIK1iagLLgEt6ZaR0rk/1jUYssyTi
# RqWr84Qs3XL/V5KUBEtUEQfQ/4RtnI09uFFUIGJZV9mD/xOUksWodGrCQSem6Hy2
# 61xMJAHqTqMuDKgwi8xk/mflr7yhXPL73SOULmu1Aqu4I7Gpe6QwNW2TtQBxM3vt
# STmdPW6rK5y0gED51RjsyK0CAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUZZ9RzoVofy+KRYiq3acxux4NAF4w
# VAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaA
# FNlBKbAPD2Ns72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVy
# aWZpZWQlMjBDb2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEF
# BQcBAQSBoTCBnjBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29u
# ZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQBFSWDU
# d08X4g5HzvVfrB1SiV8pk6XPHT9jPkCmvU/uvBzmZRAjYk2gKYR3pXoStRJaJ/lh
# jC5Dq/2R7P1YRZHCDYyK0zvSRMdE6YQtgGjmsdhzD0nCS6hVVcgfmNQscPJ1WHxb
# vG5EQgYQ0ZED1FN0MOPQzWe1zbH5Va0dSxtnodBVRjnyDYEm7sNEcvJHTG3eXzAy
# d00E5KDCsEl4z5O0mvXqwaH2PS0200E6P4WqLwgs/NmUu5+Aa8Lw/2En2VkIW7Pk
# ir4Un1jG6+tj/ehuqgFyUPPCh6kbnvk48bisi/zPjAVkj7qErr7fSYICCzJ4s4YU
# NVVHgdoFn2xbW7ZfBT3QA9zfhq9u4ExXbrVD5rxXSTFEUg2gzQq9JHxsdHyMfcCK
# LFQOXODSzcYeLpCd+r6GcoDBToyPdKccjC6mAq6+/hiMDnpvKUIHpyYEzWUeatty
# KXtMf+QrJeQ+ny5jBL+xqdOOPEz3dg7qn8/oprUrUbGLBv9fWm18fWXdAv1PCtLL
# /acMLtHoyeSVMKQYqDHb3Qm0uQ+NQ0YE4kUxSQa+W/cCzYAI32uN0nb9M4Mr1pj4
# bJZidNkM4JyYqezohILxYkgHbboJQISrQWrm5RYdyhKBpptJ9JJn0Z63LjdnzlOU
# xjlsAbQir2Wmz/OJE703BbHmQZRwzPx1vu7S5zCCB54wggWGoAMCAQICEzMAAAAH
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
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDICEzMAB1s8q7FX4tjeQFQAAAAHWzwwDQYJ
# YIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgr4zOdXS8ZgUgCkJAq4tCJvEPPleA
# CIt7sM/BkafCe/EwDQYJKoZIhvcNAQEBBQAEggGAR1ZBcxMWhHynGqA0ZJN9Ah9L
# 0ydryMBfUGmz7q6EeG8VRnw/nCFt2wees3vtmhSDFMUiGRaD2/axWMkgHbpsvfL1
# I9Kl5q5rudrJh8TtonC0tHmkAomTfcpw0MBMqzoJojk7TcpE1YquO2bOdaCfX1WA
# mmo1U6msFtvx+BVANi++hQ4ndBadOGqHqY6h+k6Z36QxrjCtKTf+vnxav66M6V7P
# Er3+i9OQwPdGU3V95KrK3rPlDqAZyJFtDmVm1ZCgJJzYsFg6P48OjcnOAtCY1VIj
# w9L+dgLsvl2dfyM5EO0RkukJUy6QHw40Zajua5JMs7Nc0+8oGqFXtA0fNa/aj9Z1
# WcwNXsVC0grp3FmssrCCn2vHD+uO8u9UPtA1uEGuUkNIYMhLGRVnaaFPMGy7UmoI
# Ntsd5nUqNxJdzmyJxHtUhyAGkYTThpDuvlA+gN9UERv44sw8fwvXGroGtiJuWrGu
# bC8pvHFamvUCqzDCGNraYuXmZS7PYDu7gA5/9BuuoYIYMTCCGC0GCisGAQQBgjcD
# AwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgBZQMEAgIF
# ADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZCgMBMEEw
# DQYJYIZIAWUDBAICBQAEMAx3QwTgRtpAx1rReA9Efo0cgkAtYwzpNys9Df0MoB59
# 0OqbeSDf0pRDP5Im7/bS7gIGaZRNZZ4qGBMyMDI2MDMxMDE0MzAwNy4yMjVaMASA
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
# 6K0NzrPDxCxyIIjnfU1s23YJhs3CC7f3XVUBETGCB1MwggdPAgEBMHgwYTELMAkG
# A1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UE
# AxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMA
# AABWfo+dWAiO6WAAAAAAAFYwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqGSIb3DQEJ
# EAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkF
# MQ8XDTI2MDMxMDE0MzAwN1owPwYJKoZIhvcNAQkEMTIEMDadY5DP2NwEiTB8eFPa
# HucfUuPMszUpyYlLfczTHhXQ2eflagym9wWf0qGDkFBbUjCBuQYLKoZIhvcNAQkQ
# Ai8xgakwgaYwgaMwgaAEILYMMyVNpOPwlXeJODleel7gJIfrTXjdn5f2jk0GAwyo
# MHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGlu
# ZyBDQSAyMDIwAhMzAAAAVn6PnVgIjulgAAAAAABWMIIDXgYLKoZIhvcNAQkQAhIx
# ggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNTAwLTA1
# RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFt
# cGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAP9z9ykVKpBZgF5eCDJEnZlu
# 9gQRoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFt
# cGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7Vp7ODAiGA8yMDI2MDMxMDEx
# MTI1NloYDzIwMjYwMzExMTExMjU2WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDt
# Wns4AgEAMAcCAQACAgN/MAcCAQACAhAsMAoCBQDtW8y4AgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBAIXMhNsEUVrIibC1wbkF+snJuV4HsS9DpI2JPZbGpU8T
# fUQ02Yo6BjvoBpG1l0owFygaCTquJw8kDVwRuRlPsb7CJ2zK1FQvJiMAD5RPMK//
# 1FlD1JgZK1WpW5Pukvv4V2osS9zFbY8QPV1em75xz7+Ksntb4MIB9JOvlwoccdum
# cIkGo+Ch4dIY31DO0Rq6Ee0rNpb/odKL6oh3DLwsJ/B/DO1gzmdJTtT1fjKlVtwK
# dUo0j8N6+S0LbLt5RUZHPLF1B4Pe2N0opKX1jLEJWA2IvT6lQUDQceMlA466Cme5
# oRTkD+ptIt6vwv7P7ucC1R+qiVjRoUFzDr2eRyrPRzkwDQYJKoZIhvcNAQEBBQAE
# ggIAnKPG3h8IW+Vuu9p0LoBUy4nIkX7jKYRhbF8DEGMET+kisGQqPLB/LPJTnNfp
# 6jkkjItyOxoTdmHWhB2jyx2VEg7GKsocbM91Is0LcnopkuyIYv/10G/oVQ2YniSN
# LxLajO0nCD6IT20e+sKr2jBUduENAqCxBVXhDQxGriFvRZCWOUVuVKMoIV1IwA7c
# mV+n4Nz5mhu60SWaLiiIPGrFXdd4knQviWAxWB9g0e+zDU/tldUYBu2+JcP2rw20
# mw1/0ZvWxzdjHbAjLc3/iGgsi0jvPDqBmMYUuVQkk2PCVe3V03IpYp8cqmB8efE6
# TYDbNsFY+qMj6YZlTXsfRTbhv3LKz2fr568ZWaZ2h6+PlEAJ/bDNYLug6QfHxTfe
# NQgomH7TKmZM4tsmf6mGdgpbinwj2e84xRmI6nvQgVSIcaI3ZIeZXRGrP69X3sCF
# 8eSg4vwr/eE2lpfr/Q8NPzobclTN3Q8YMhMRuq5I45TyW62FVPhjNC6uKAqOPtkD
# RV8xhJcRG5wy2UgQlhuIP/qbeU+Mj9/7EnrfHMiBxEjTXBiv+38kKp6j65k80Ow3
# U1IYpdQKPEQXZ56WNnbK6ReTGNg0DsZpMq5+TeDkSenC/n3xxxhxSuShPwQf5XpQ
# kf37SzXD+XuYAny6OCmmEtuXHRrNz907gS0rTFTIgWp2GuA=
# SIG # End signature block
