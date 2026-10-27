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
# MII9RAYJKoZIhvcNAQcCoII9NTCCPTECAQExDzANBglghkgBZQMEAgEFADB5Bgor
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAlPwZ0U
# NZg+KL02AAAACU/BMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDMwHhcNMjYxMDI2MDMwNjE5WhcNMjYxMDI5
# MDMwNjE5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAne8/
# yOpktSa2wEN5w6k/6fxRxth0JcHLKE3xMH1MaoDK+4ixyTR4wpCGP0Hh/aNVohWX
# l52HZfQezLUKfqUSQzyNMK/gItZP+kjulvqvSrcWd9Q8i1+fH6hSDx1fz1okpzEY
# PpaD0Z1beHntTBNtumvCHuirNhSZx8duxOFxTAgihB5/eLoxhrdey6ZVMvnJXl6V
# vpv++MvnY290Vgp7v2gK9yJMpy8MJkTkMXIVy1lPjqLh4yjVG2BV1Ra3bp4jPXX9
# oWfqVSVHFvZuuL8CmRMuKBGtCbf9/cOGgI9yvrtx594qbN9tecuYo7+jesL74fFo
# c1xQKwcPgczD+eh/f2QaWy+3C0dCmOsgbaE0u0rjI+xD6bqJ7h+VXSairkYzecJl
# nNDNlRC/ojFv66vo1YAMTxhGqUJobrwHNMDWruSsupGpqk5AFA48HVcjbLGfmuYA
# FqXi1gW+/6Jy+fZgiJzsSeqvQbh4qgwlXOpoqOlmbZkb7H2HuT/4w2Z3sqCnAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUqGrZxbmjWZBjvJ8p+76Z5pff5bswHwYDVR0jBBgw
# FoAUa16lNMMFxWJKIVqOq3NgYtSsY4UwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwMy5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDMuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAIocnMejmRBcBlAoSZoJGF9ogDC332u3DR3wYfS0aUWm
# U+rKAyku2kFODmIIpkoTLhz1+nzLMu8p5e2bR7MlrAJ/GwIJ9cTQmGIuW+4HLU09
# EQeVhSwS3IYQBaHD+dcX8Sdc10mB4pH6eJzwqLkwL2nKWtL1Qx61IhNNlj3cUyD7
# Eln6Lg30gSGNHJsT8LYPya64IlnaVi3gm9sdrnSVdlileug+CZ912a2k4BiDRcVC
# NXZ2VNZWf5FXwLIw/qc0AEAb4TirkQjwB0OUUYzJmpexERZ2k3GPIxQ1NswgVTvW
# wg+PfSJP0MrIemb5D7QLPXlwSoxYfTgoFqQXoavectcrjq7cydtpKzUnzBkOJoyt
# DUghWyDH/9J0ig5xH0PLGwrQ/AKkj5nk/Z8/23X4N1DIkf1iCy9D9dIYDfyWJ4R0
# /GG/dzE3+z8b+We0khV9TchzoPo43t2UMfrTCb7Va+bXZA5wlcubHSXj5XOjborp
# CUCYz5MwoewvwdbGHoLAj60ycCQd2EVyzbrL9BboGq1f4Guxf1HJ09lTj50SwnNA
# Hn9EsSreehrgkYO9/4kQPl8Q6BMwzwAXZm7pwSBywTjdeua+snsrX0cUrznZzmcP
# kSIN8XHaKRL2/Avww6O6o/W9Vly/tkdtEqmnJ5J4ONRRjJ5Zk6VVCTlPB1FmgH7O
# MIIGojCCBIqgAwIBAgITMwAJT8GdFDWYPii9NgAAAAlPwTANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDAzMB4X
# DTI2MTAyNjAzMDYxOVoXDTI2MTAyOTAzMDYxOVowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBAJ3vP8jqZLUmtsBDecOpP+n8UcbYdCXByyhN8TB9
# TGqAyvuIsck0eMKQhj9B4f2jVaIVl5edh2X0Hsy1Cn6lEkM8jTCv4CLWT/pI7pb6
# r0q3FnfUPItfnx+oUg8dX89aJKcxGD6Wg9GdW3h57UwTbbprwh7oqzYUmcfHbsTh
# cUwIIoQef3i6MYa3XsumVTL5yV5elb6b/vjL52NvdFYKe79oCvciTKcvDCZE5DFy
# FctZT46i4eMo1RtgVdUWt26eIz11/aFn6lUlRxb2bri/ApkTLigRrQm3/f3DhoCP
# cr67cefeKmzfbXnLmKO/o3rC++HxaHNcUCsHD4HMw/nof39kGlsvtwtHQpjrIG2h
# NLtK4yPsQ+m6ie4flV0moq5GM3nCZZzQzZUQv6Ixb+ur6NWADE8YRqlCaG68BzTA
# 1q7krLqRqapOQBQOPB1XI2yxn5rmABal4tYFvv+icvn2YIic7Enqr0G4eKoMJVzq
# aKjpZm2ZG+x9h7k/+MNmd7KgpwIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFKhq2cW5o1mQ
# Y7yfKfu+meaX3+W7MB8GA1UdIwQYMBaAFGtepTTDBcViSiFajqtzYGLUrGOFMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDMuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDAzLmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQCKHJzHo5kQXAZQ
# KEmaCRhfaIAwt99rtw0d8GH0tGlFplPqygMpLtpBTg5iCKZKEy4c9fp8yzLvKeXt
# m0ezJawCfxsCCfXE0JhiLlvuBy1NPREHlYUsEtyGEAWhw/nXF/EnXNdJgeKR+nic
# 8Ki5MC9pylrS9UMetSITTZY93FMg+xJZ+i4N9IEhjRybE/C2D8muuCJZ2lYt4Jvb
# Ha50lXZYpXroPgmfddmtpOAYg0XFQjV2dlTWVn+RV8CyMP6nNABAG+E4q5EI8AdD
# lFGMyZqXsREWdpNxjyMUNTbMIFU71sIPj30iT9DKyHpm+Q+0Cz15cEqMWH04KBak
# F6Gr3nLXK46u3MnbaSs1J8wZDiaMrQ1IIVsgx//SdIoOcR9DyxsK0PwCpI+Z5P2f
# P9t1+DdQyJH9YgsvQ/XSGA38lieEdPxhv3cxN/s/G/lntJIVfU3Ic6D6ON7dlDH6
# 0wm+1Wvm12QOcJXLmx0l4+Vzo26K6QlAmM+TMKHsL8HWxh6CwI+tMnAkHdhFcs26
# y/QW6BqtX+BrsX9RydPZU4+dEsJzQB5/RLEq3noa4JGDvf+JED5fEOgTMM8AF2Zu
# 6cEgcsE43XrmvrJ7K19HFK852c5nD5EiDfFx2ikS9vwL8MOjuqP1vVZcv7ZHbRKp
# pyeSeDjUUYyeWZOlVQk5TwdRZoB+zjCCBygwggUQoAMCAQICEzMAAAAVBT5uGY6T
# KdkAAAAAABUwDQYJKoZIhvcNAQEMBQAwYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZl
# cmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTAeFw0yNjAzMjYxODExMjhaFw0z
# MTAzMjYxODExMjhaMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBF
# T0MgQ0EgMDMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDg9Ms9Aqov
# DnMePvMOe+KybhCd8+lokzYORlS3kBVXseecbyGwBcsenlm5bLtMGPjiIFLzBQF+
# ghlVV/U29q5GcdeEEBCHTTGhL2koIrLc4UrliMRcbv9mOMtR/l7/xAmv0Fx4BJHn
# 1dHt37fvrBqXmKjKfGf5DpyO/+hnV7TEreMtS19iO+bjZ/9Hnpg3PCk0e7YSbRTF
# kx97FZwRWpC4s3NepRfRXQh/WMAj7JmsYeVZohi4TF5yW2JMrJZqwHcyzJZYtD2H
# lno5ZEJkdiZcEaxHOobmwO06Z1J9c23ps9PGIhGaq1sKLEAz9Doc5rLkYWGteDrs
# cKhAp2kIc/oYlH9Ij6BkOqqgWINEkEtC8ZNG1Mak+h3o65aj0iQKmdxW7IZaHO5c
# uyoMi+KtYfXeIIg3sVIbS2EL8kUtsDGdEqNqAq/isqTi1jXqLe6iKp1ni1SPdvPW
# 9G03CTsYF68b/yuIQRwbdoBCXemMNJCS0dorCRY4b2WAAy4ng7SANcEgrBgZf535
# +QfLU5hGzrKjIpbMabauWb5FKWUKkMsPcXFkXRWO4noKPm4KWlFypqOpbJ/KONVR
# eIlxHQRegAOBzIhRB7gr9IDQ1sc2MgOgQ+xVGW4oq4HD0mfAiwiyLskZrkaQ7Joa
# nYjBNcR9RS26YxAVbcBtLitFTzCIEg5ZdQIDAQABo4IB3DCCAdgwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRrXqU0wwXFYkohWo6r
# c2Bi1KxjhTBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBkG
# CSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYD
# VR0jBBgwFoAU2UEpsA8PY2zvadf1zSmepEhqMOYwcAYDVR0fBGkwZzBloGOgYYZf
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# SUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyMS5jcmww
# fQYIKwYBBQUHAQEEcTBvMG0GCCsGAQUFBzAChmFodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3J0MA0GCSqGSIb3DQEBDAUAA4IC
# AQBdbiI8zwXLX8glJEh/8Q22UMCUhWBO46Z9FPhwOR3mdlqRVLkYOon/MczUwrjD
# hx3X99SPH5PSflkGoTvnO9ZWHM5YFVYpO7NYuB+mfVSGAGZwiGOASWk0i2B7vn9n
# ElJJmoiXxugfH5YdBsrUgTt0AFNXkzmqTgk+S1Hxb1u/0HCqEHVZPk2A/6eJXYbt
# pRM5Fcz00jisUl9BRZgSebODV85bBzOveqyC3f0PnHCxRJNhMb8xP/sB/VI7pf2r
# heSV7zqUSv8vn/fIMblXeaVIlpqoq8SP9BJMjE/CoVXJxnkZQRM1Fa7kN9yztvRe
# OhxSgPgpZx/Xl/jkwyEFVJTBfBp3sTgfIc/pmqv2ehtakL2AEj78EmOPQohxJT3w
# yX+P78GA25tLpAvzj3RMMHd8z18ZuuVi+60MAzGpOASH1L8Nlr3fZRZnQO+pyye2
# DCvYmHaIfdUgYJqn7noxxGVv89+RaETh1tgCDvwNpFCSG7vl5A4ako+2fx409r9T
# WjXC7Oif1IQ5ZJzB4Rf8GvBiHYjvMmHpledp1FGRLdSRFVpC3/OKpZY6avIqZp7+
# 8pP/WQP903DdgrvAT6W4xPOBxXPa4tGksN3SuqJaiFYHSNyeBufn8iseujW4IbBS
# bHD4BPqbF3qZ+7nG9d/d/G2/Lx4kH9cCmBfmsZdSkHmukDCCB54wggWGoAMCAQIC
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
# DT2uhJ04ji+tHD6n58vhavFIrmcxghqwMIIarAIBATBxMFoxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jv
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDMCEzMACU/BnRQ1mD4ovTYAAAAJ
# T8EwDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgr4zOdXS8ZgUgCkJAq4tC
# JvEPPleACIt7sM/BkafCe/EwDQYJKoZIhvcNAQEBBQAEggGAJjkWPqKYGs+oo1HR
# TXUVrI6n/7r3tOe/loTvzfEMxGW29tVyzH3gue79J3/4N4xQQOTcfRIUvRAOu+/v
# BcziB5oMDa+nF88GjWbbt0vLLiSIGMKTTCpPyC3J5OhaiWP2mwST96cQ2hx1A0Fx
# kcW3CRBdzXfGztcWDS0t8Gso4GctbQgc66G1xvvtL4R9AliNpHyA9HlL87jeeRQ7
# r2NzNFxIDgEBMk0hKkFTypXNUMv3Qe60t7r0lk5YApvv306OyZtk78rHQhn4E+ZJ
# YWNP6fLpAIeHOB6UGRwSHsyLXGaoem8kIf9IqBTParXDr6QAD5gVuF3aRbNzJHOd
# 1stTUlNu3cA1GULPvK0ay0mP++ImODeFcc/1laTeMiFJXrxN+gnkjncZ6L1ncqT7
# FfWDeYlTyHEiAsjaVaPWNjjb4wMXzj2QmzYuAamsOK4SwVYd8DqnELbQhRtPaf4t
# axLk0V6unLbhPzul6v1xuTnQ3rA/TyrrXYBaNt7htLwsk90UoYIYMDCCGCwGCisG
# AQQBgjcDAwExghgcMIIYGAYJKoZIhvcNAQcCoIIYCTCCGAUCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMPnVyylFbsMMvj9rXTH7MXHakm59yvBEe4LA
# oH7Kcw0N0IbS1CiCQEYbFGmC2XmIFQIGauColxN2GBMyMDI2MTAyNzE4MTUxOC45
# OTlaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTUwMC0wNUUwLUQ5NDcxNTAzBgNVBAMT
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
# GHumaABdWzCCB5cwggV/oAMCAQICEzMAAABgcgYkikoFuNkAAAAAAGAwDQYJKoZI
# hvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjAwHhcNMjYwOTE3MTg1NzI3WhcNMjcwOTE0MTg1NzI3WjCB2zEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOkE1MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAJoTY0vAU8eK+kN8x4BKnIlH9iQTFcIiEQlfNr5cc5jWEaQDpqjZ
# p3vU/BSRYGenvTs+oHs4UQfhfBePUoupwfvrE/rknRbMV05RfK585gQXn4v2eKIW
# StrcQldJzXDMO4SAk7xBKjYCuGZaXIV1a/HIWPsVCyskVGqzVxiO8mm4L4j1qZmA
# flvxqB5Z31ei3eWp2Dch+FEjk0lVUAP9SKV/vRuDu9LnZr3tJzV0zB2marXLbk+/
# oi2paegA9lFpINFP6M7y9WVTxmN1yKqaD+ESDlNkifkPb/CAN3mXiDbQCJwSvPAv
# uwBb38naq7uj74DsmcJu+/CQJq3wQgPhYzmOH8n2ooNZSXNdf/bEfi+uwWy1648Z
# m5ujDYMYyfei/S48lVSkVuOTGxMKFn2KcZEmezeVc/dPP2uLaIMl2KoaY3Js1HcG
# EH17ykl2TBBecVBinn834VnHzjkRG+p31CjE1zSCChED1Fa0qdOMCn/akDtbJOir
# aBD9eGRNYSNgfJCwKaRv/wlig8yjFAk1Dcs/ExnkvzMGfLE+WreJ/BmE499S072u
# PWDU4oSQCwUmYnMkZ+4vBNzUBuS4ZVOkU5yjRglZzHSCv1BV8U5VmEEBd7Ddxc0a
# Ul5uZNQz2o4jkKivfxgxBRZzgqKO6JCwoap+lR6S5LiLUEDwbj2xyOLfAgMBAAGj
# ggHLMIIBxzAdBgNVHQ4EFgQUiFQodGFQBDsTCbiC3pKjt17aamIwHwYDVR0jBBgw
# FoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcB
# AQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5n
# JTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4IC
# AQBXi+Z/KQU0lz0ZtOXYnG5vgrmi6XADP5Aoe8sSm6Oy2NcWIcOciGv3pTli46YV
# VrnxoJ5xFwaquNrhgzzgMxURR7gZcPIduwsZbqLEzHMbPBK7Pa4EG+zYJxxzbn3M
# 5q+5c5+3ZCE5y8GKOJddsW5JI9lcAtS9HmLW4SRI7Km4F52jh9QKzj2/68al7Z2q
# xLg72YgTMGzZey5EF5U5g0o4fAJxeVfDgprwHks+wzBt8w7cZhW381dAbHiVk89W
# Yic017zglRodLAgtJvsVQcaZ/nxPJLLZCiFTvA+DGawLfa6EBWB/wCqN3Z0466vP
# FLgO+qqUWmYa9Ps39ohdICgBwYBmDzZz2e9yB0ESTEIn0gqvzKFkGt/Dt7H2nA0d
# r4Mbw2fo36Oy0BV4PggoB9oc+h2X4Xw/Ep03vZgGB2P0TGh4UffoydKpW7xYx2hA
# Rd4rAKlqKbEyVlQzDxMuO4cDiH5AMi/XOP3HCJc0tJxR0SsYTeeDl9Tf2zcGccG0
# hy6F+2PlUnVhH6f8K521KHyOSsoWoHuIGTjGV7d93McVRRga05KqTbsTawGFr/bY
# TH3UhELxlXpQIC8nnTI0JFf3vFA/5WuzefHVnc3DZVxW3zUXvxYc7H+Eq1tSJZch
# blyNhrGcl2NSh4QpwBpPKeLXeCSLgyFbaukaAV4QJdIAFjGCB1IwggdOAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABgcgYkikoFuNkAAAAAAGAwDQYJYIZIAWUDBAICBQCgggSrMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MTAyNzE4MTUxOFowPwYJKoZIhvcNAQkEMTIEMEmDeUkwuzI+
# jkdSJj7VgNNlEW2ZOz0J0617cfOftk9WQUAMtu0R5LArsSBFsX4KEjCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEIDfLjLnwvS54utKqPKxmcYlH7Orna0xc019M
# pXpStgKzMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAYHIGJIpKBbjZAAAAAABgMIIDXQYLKoZIhvcN
# AQkQAhIxggNMMIIDSKGCA0QwggNAMIICKAIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpB
# NTAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAJe/M8jCvUlk8+It
# Y60JUWKjdUI3oGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7osnGDAiGA8yMDI2
# MTAyNzEzMzUyMFoYDzIwMjYxMDI4MTMzNTIwWjBzMDkGCisGAQQBhFkKBAExKzAp
# MAoCBQDuiycYAgEAMAYCAQACAUkwBwIBAAICDB0wCgIFAO6MeJgCAQAwNgYKKwYB
# BAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGG
# oDANBgkqhkiG9w0BAQsFAAOCAQEAibB4b6h8YfjilZk61VGdujA1U5wjqn2gQAXs
# w4iRwQHGzG9Uz39wgoiUHfTd3Hr7CheLmhFJ3ED0zfuQQdi5E0TIldlFSP2vlsDo
# 1MUpnQH/BMaNGuEgcy7Iqik8eqh3fkzJMB0vrbjs3SoIXtMiGCCDNFecq3kXTvUT
# wuk9HtcB9e46yOFRlxSS1Zp92ZqYIC/jWFS4FDCV1mHigeOJGlkUwt9L0kX2Qich
# BH4/pFm6JJoR/F3rcOOU3hgaCiuOqxTzpqpEk5NEFLPA1lXQH7+4Wdl3eEiI9pBn
# SlHi5RsSGRWzhPmWWgKeQhJPxuTXH583DO7SUm6SAjMSRR4lqzANBgkqhkiG9w0B
# AQEFAASCAgBsP9fJzMEkf7+Y39C4C22ddTZ1FZEU9kuw50cna+Bg3KXiM41XY0eq
# uzs8yn5M7/dipJWzqvmkSu4BmaNyj4xLtDJLkNEJE1RLm8riUrjw42bs3rCbyj9t
# 2UWYpB1mxxAjI99TKRsLu48muI/dZOUT+EUruqE+Nmb7sv4JhaD4couymmhwuuu1
# HwODcd5XT/8iLFdEDES5xdypO9Kz6KXvd4RlX9RFpvdfYVXy8ha148Gk3ZYgyCn3
# CncxfrWsWShBmzDiFOButMdhzJdNmj2xtu56v0Atn8OZmzvTi5c7ZhLEcHnOY8bz
# Tyg8Gl/QPrb20aCGFZN8LL7MB3DUBIq6lW2pHLoRFu+1ZQ/dn70xhsJPXIBdQXIO
# fOd9pNZPEoGxyXTbnS5XYS9TKqtjQ4yeusiSzF/fB5uQLEaUvfqmex61KCsce0O1
# O9tOkMu53ezuh6CoF9RmzUonuADn4PFiS06SeZwXU45BlYU7ysXSH9vGfE5l1i25
# a4QPZzJkuV9LVlrCWSdY/lKfqWvDNDK9yShbgQyDc+ueA4xcxSAIPTY6YBCBcerZ
# sF0ftnZxevmwc3y2G5IHSuKkplG5XsJBQ/1HTqXcWgqN7Ik8arFID/ja737g9uiK
# VdKuSIw7/pc7uTcVL9/M8bo/F1mnI0hF/RWgYLb+7ASbRMCoUOpN9Q==
# SIG # End signature block
