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
# MII55gYJKoZIhvcNAQcCoII51zCCOdMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAFl60qY
# U0Ge9c8aAAAAAWXrMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDMwHhcNMjYwNTI2MDMyMjU4WhcNMjYwNTI5
# MDMyMjU4WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAnv7i
# qtoWid9VngMUzIRG0BMbml3tYImwjGI+e9YpAu18G+sUp/AbTomqE5beRRnBnFsa
# tyhg13OnTrxRNtAdhOv7XpYyXsL/VV5QW65WFiG5Vyd0iTF6MUld+rgmcsLow5op
# dAS1Pqx5/l122t4/PbdNXuEM3w4mJs9zKr88ycwg+X6QDpxHp39gFIm2qKUtf24w
# m/YlGLoQ2mv+A8VCsoSbQR1W1CECBUDlBxMLS5yMSLjoAplvNwolE5QflPvp/vCV
# oytPZWnxOojsmIHGIl4wcG3N0SK+LaHCgM1VKncqSvonDVVSegD716Cn8Wf3rOq+
# e8r8dfLEee4bmlmWhLHRHYfflpgmaQmbLR4EiP3HeemY9ep5zRsw7g/BoQ0sdike
# mYkJ8YsBIrNUTx6+NQyDquI7ABYG71yjDGmGJBDE9qDJkrXmwqgBLa8U//A54bDP
# 2XbaGnHpYfiiCXkbMfuCtmi2Y37fL2YfTwoNqZwm6qSx6Xt7QBb6v5gR0uozAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUOmtn5pNuokXGiHR+luy/DHPJuo4wHwYDVR0jBBgw
# FoAUa16lNMMFxWJKIVqOq3NgYtSsY4UwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwMy5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDMuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAKRL/GKK9LdANNr9mo0mPVXMkV1N3EGVI2LwT6z3wj5M
# 6EGjvGDO0yTeApqSgvKJbbqo2hkj1JY0Ke/C1nBmsDxk9mkMMzBcpZ+dJp5pAg0u
# 0pRlFQgacYsVUH3OKjB0TVDk/9e3b9eJyVAXS4pZV0Phq/o8wlXuOdwtWkjeZmm9
# wJ30CemHdDlRSxkUpn5lI3x4BHbG3wZEaQWPwaRUURZZc0x3jkLuY2BCnfVHq5Dz
# poRTnzHfp6evmvHKJorYfZcYHctEB3rhS5VUEIGJgKQeA8aPKypnEVq3fjXL5CES
# aLk5v+1D78XmnOT90qdwiQXGRfzDV6Ydh2T2eUEUWQNwqIzka7gekKMLcnbPUo26
# O8W4Mb1+VXyovfr4wmpKD/awTOl7IcXLU0wMeloeASasMVfSa63hc6Lp1UrETTlV
# Hx4zApXMHPg72x8vpXZsXIdaTmWNEpSxlruaEnISVdl+Cypga2KKmGbvUFstb8Mo
# AX+xoLI/F4bQe6J9qRfPZApsXWjB2Kyan+/unlfOQ3NH4ikuA4ydDZrsROofcst0
# 40V6k8bePyEm8BIQTGWHi0x0L7MNyldOdCG3+T6ie3naxM9+2TMwEphR0GQc+FGj
# MUl6rERTezLy2g0/1dOOzSscVsF2T8WSvWuU+5BHUVn5TdT/B+VqdawgsSbMYIQi
# MIIGojCCBIqgAwIBAgITMwABZetKmFNBnvXPGgAAAAFl6zANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDAzMB4X
# DTI2MDUyNjAzMjI1OFoXDTI2MDUyOTAzMjI1OFowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBAJ7+4qraFonfVZ4DFMyERtATG5pd7WCJsIxiPnvW
# KQLtfBvrFKfwG06JqhOW3kUZwZxbGrcoYNdzp068UTbQHYTr+16WMl7C/1VeUFuu
# VhYhuVcndIkxejFJXfq4JnLC6MOaKXQEtT6sef5ddtrePz23TV7hDN8OJibPcyq/
# PMnMIPl+kA6cR6d/YBSJtqilLX9uMJv2JRi6ENpr/gPFQrKEm0EdVtQhAgVA5QcT
# C0ucjEi46AKZbzcKJROUH5T76f7wlaMrT2Vp8TqI7JiBxiJeMHBtzdEivi2hwoDN
# VSp3Kkr6Jw1VUnoA+9egp/Fn96zqvnvK/HXyxHnuG5pZloSx0R2H35aYJmkJmy0e
# BIj9x3npmPXqec0bMO4PwaENLHYpHpmJCfGLASKzVE8evjUMg6riOwAWBu9cowxp
# hiQQxPagyZK15sKoAS2vFP/wOeGwz9l22hpx6WH4ogl5GzH7grZotmN+3y9mH08K
# DamcJuqksel7e0AW+r+YEdLqMwIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFDprZ+aTbqJF
# xoh0fpbsvwxzybqOMB8GA1UdIwQYMBaAFGtepTTDBcViSiFajqtzYGLUrGOFMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDMuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDAzLmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQCkS/xiivS3QDTa
# /ZqNJj1VzJFdTdxBlSNi8E+s98I+TOhBo7xgztMk3gKakoLyiW26qNoZI9SWNCnv
# wtZwZrA8ZPZpDDMwXKWfnSaeaQINLtKUZRUIGnGLFVB9ziowdE1Q5P/Xt2/XiclQ
# F0uKWVdD4av6PMJV7jncLVpI3mZpvcCd9Anph3Q5UUsZFKZ+ZSN8eAR2xt8GRGkF
# j8GkVFEWWXNMd45C7mNgQp31R6uQ86aEU58x36enr5rxyiaK2H2XGB3LRAd64UuV
# VBCBiYCkHgPGjysqZxFat341y+QhEmi5Ob/tQ+/F5pzk/dKncIkFxkX8w1emHYdk
# 9nlBFFkDcKiM5Gu4HpCjC3J2z1KNujvFuDG9flV8qL36+MJqSg/2sEzpeyHFy1NM
# DHpaHgEmrDFX0mut4XOi6dVKxE05VR8eMwKVzBz4O9sfL6V2bFyHWk5ljRKUsZa7
# mhJyElXZfgsqYGtiiphm71BbLW/DKAF/saCyPxeG0HuifakXz2QKbF1owdismp/v
# 7p5XzkNzR+IpLgOMnQ2a7ETqH3LLdONFepPG3j8hJvASEExlh4tMdC+zDcpXTnQh
# t/k+ont52sTPftkzMBKYUdBkHPhRozFJeqxEU3sy8toNP9XTjs0rHFbBdk/Fkr1r
# lPuQR1FZ+U3U/wflanWsILEmzGCEIjCCBygwggUQoAMCAQICEzMAAAAVBT5uGY6T
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
# DT2uhJ04ji+tHD6n58vhavFIrmcxghdSMIIXTgIBATBxMFoxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jv
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDMCEzMAAWXrSphTQZ71zxoAAAAB
# ZeswDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgr4zOdXS8ZgUgCkJAq4tC
# JvEPPleACIt7sM/BkafCe/EwDQYJKoZIhvcNAQEBBQAEggGAHoQpSyoaJWI7gSwD
# EAtdPvd2TONOILbAj8rfDkimQhXsac/tcXodKpiTn+FW/orUAOhzz53AqAKEP5Ze
# HGdJbl75q1jd/hzR2V/X9ccxSk66XUSLNXlPWVJ+fSWy2tBjS0jXK3UXDXBss28u
# mPtxaWLQiUEjfo0qiNOulv4Vydi3vIwU+w6k5WVFC3PtTeopW6EuSyXniQDXGGwu
# Z7m+8olykcztSG2gI7Ha3Jhf7eb9zA7W5TJGDqrrhpMunmDQACtoKBpJ0/oQ+EAk
# pRAdJg4hJj6rdWrZwOrAn7tvnjuz5qzW24JPHyeunt0v69JANAHR7Ih096WMFiCY
# gMUd5mTe4yS7V2kX1E46wPvVsY1CymdwZz38N+kz7HGckQGcy2eBAUN3MNSrOhgy
# ltijKSR1GR/9PRgWZQDAT3EODqOR4aJsCgdvoBgd5grGFgJjNsMTPJSKpJ2ZA8bm
# r77unf/5Vjh3eZ0nRqKifbHWUDiZ81klNM46wMbn0CE1cd5YoYIU0jCCFM4GCisG
# AQQBgjcDAwExghS+MIIUugYJKoZIhvcNAQcCoIIUqzCCFKcCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXoGCyqGSIb3DQEJEAEEoIIBaQSCAWUwggFhAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMKsz8WB5BXB/IKV4NzfSwp+XfRZIqSV2w/XU
# 45UxOwO59OqUMLxL6PK1/90lMszNjAIGahBbo1pxGBMyMDI2MDUyNjE3MDg1Mi4z
# MDlaMASAAgH0oIHppIHmMIHjMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExp
# bWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3QjFBLTA1RTAtRDk0NzE1
# MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFtcGluZyBBdXRo
# b3JpdHmggg8pMIIHgjCCBWqgAwIBAgITMwAAAAXlzw//Zi7JhwAAAAAABTANBgkq
# hkiG9w0BAQwFADB3MQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMUgwRgYDVQQDEz9NaWNyb3NvZnQgSWRlbnRpdHkgVmVyaWZpY2F0
# aW9uIFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMjAwHhcNMjAxMTE5MjAz
# MjMxWhcNMzUxMTE5MjA0MjMxWjBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lc3RhbXBpbmcgQ0EgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
# AgoCggIBAJ5851Jj/eDFnwV9Y7UGIqMcHtfnlzPREwW9ZUZHd5HBXXBvf7KrQ5cM
# SqFSHGqg2/qJhYqOQxwuEQXG8kB41wsDJP5d0zmLYKAY8Zxv3lYkuLDsfMuIEqvG
# YOPURAH+Ybl4SJEESnt0MbPEoKdNihwM5xGv0rGofJ1qOYSTNcc55EbBT7uq3wx3
# mXhtVmtcCEr5ZKTkKKE1CxZvNPWdGWJUPC6e4uRfWHIhZcgCsJ+sozf5EeH5KrlF
# nxpjKKTavwfFP6XaGZGWUG8TZaiTogRoAlqcevbiqioUz1Yt4FRK53P6ovnUfANj
# IgM9JDdJ4e0qiDRm5sOTiEQtBLGd9Vhd1MadxoGcHrRCsS5rO9yhv2fjJHrmlQ0E
# IXmp4DhDBieKUGR+eZ4CNE3ctW4uvSDQVeSp9h1SaPV8UWEfyTxgGjOsRpeexIve
# R1MPTVf7gt8hY64XNPO6iyUGsEgt8c2PxF87E+CO7A28TpjNq5eLiiunhKbq0Xbj
# kNoU5JhtYUrlmAbpxRjb9tSreDdtACpm3rkpxp7AQndnI0Shu/fk1/rE3oWsDqMX
# 3jjv40e8KN5YsJBnczyWB4JyeeFMW3JBfdeAKhzohFe8U5w9WuvcP1E8cIxLoKSD
# zCCBOu0hWdjzKNu8Y5SwB1lt5dQhABYyzR3dxEO/T1K/BVF3rV69AgMBAAGjggIb
# MIICFzAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYE
# FGtpKDo1L0hjQM972K9J6T7ZPdshMFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsG
# AQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVw
# b3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAwe
# CgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSob
# yhmYBAcnz1AQT2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJp
# ZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIw
# LmNybDCBlAYIKwYBBQUHAQEEgYcwgYQwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5
# JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5
# JTIwMjAyMC5jcnQwDQYJKoZIhvcNAQEMBQADggIBAF+Idsd+bbVaFXXnTHho+k7h
# 2ESZJRWluLE0Oa/pO+4ge/XEizXvhs0Y7+KVYyb4nHlugBesnFqBGEdC2IWmtKMy
# S1OWIviwpnK3aL5JedwzbeBF7POyg6IGG/XhhJ3UqWeWTO+Czb1c2NP5zyEh89F7
# 2u9UIw+IfvM9lzDmc2O2END7MPnrcjWdQnrLn1Ntday7JSyrDvBdmgbNnCKNZPmh
# zoa8PccOiQljjTW6GePe5sGFuRHzdFt8y+bN2neF7Zu8hTO1I64XNGqst8S+w+RU
# die8fXC1jKu3m9KGIqF4aldrYBamyh3g4nJPj/LR2CBaLyD+2BuGZCVmoNR/dSpR
# Cxlot0i79dKOChmoONqbMI8m04uLaEHAv4qwKHQ1vBzbV/nG89LDKbRSSvijmwJw
# xRxLLpMQ/u4xXxFfR4f/gksSkbJp7oqLwliDm/h+w0aJ/U5ccnYhYb7vPKNMN+SZ
# DWycU5ODIRfyoGl59BsXR/HpRGtiJquOYGmvA/pk5vC1lcnbeMrcWD/26ozePQ/T
# WfNXKBOmkFpvPE8CH+EeGGWzqTCjdAsno2jzTeNSxlx3glDGJgcdz5D/AAxw9Sdg
# q/+rY7jjgs7X6fqPTXPmaCAJKVHAP19oEjJIBwD1LyHbaEgBxFCogYSOiUIr0Xqc
# r1nJfiWG2GwYe6ZoAF1bMIIHnzCCBYegAwIBAgITMwAAAFl82nHpjV71wAAAAAAA
# WTANBgkqhkiG9w0BAQwFADBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBU
# aW1lc3RhbXBpbmcgQ0EgMjAyMDAeFw0yNjAxMDgxODU5MDFaFw0yNzAxMDcxODU5
# MDFaMIHjMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYD
# VQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNV
# BAsTHm5TaGllbGQgVFNTIEVTTjo3QjFBLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWlj
# cm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFtcGluZyBBdXRob3JpdHkwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCmLuf+NHhF/oU/uYxWteOm4nd3QOC5
# 12J7b5D9whsOCxgERYZ7yzEif1bbLm8w2nhZ5u8m9ikjO9Fph0Ka3Qlaqb1B+5dL
# geIzcO7qy6AEfZChyxNFZTJQ0rQ0sVASN6sLHa473Zr1dJPvf547gxIkpcyU3+w6
# MHdSt2zuG3kcmhYUfmPLcphAjqpTgH32KxtsGXVTOdfkEgUnvjxMpK/Aujp56koq
# bhfH2bwm+v4bpNGZumcLGosUhyAE9iBBr0u3OtyJvI1d2vEdCuotsosNDTZZ00qc
# Mv2X7+4sLCwcIX24wU5/lzpepj8w10EN1fkkT/cV2xijrAU8cxone2igB8N6OAIZ
# fVBlix/ZDT91VKJBOiWJI5X6blBmeoEMqg3sH8Q+FaGCJaKbeB2dMUL6mo7icfnK
# /C0fyGeeoCy5sMjM3Xufr7YwaIpa8v4EmcFRsIJL5CIKSjwUBxrEgdMt7M6+2O8B
# G+r9MmWpdV1L1p5894p02klrAhayz1cFZl8t53GOf3duVaTpIbfpuvexljW77DTo
# QDh0Wn7RPY/4YZKDOkbMiXwS54ajHAP8HGr3+aI+TXskUHRmXiynJbPXLCkt7AVM
# z4nccdoojR/Qj2g6v2yyRDl2rGKIVzJ0Yp7vn1JPNbPFTuw0Ehen35+aKkh6FfJX
# 9QMervpHUoW/AQIDAQABo4IByzCCAccwHQYDVR0OBBYEFI+W5wtfA9L5Z0kYQjoj
# gxhrlzZ2MB8GA1UdIwQYMBaAFGtpKDo1L0hjQM972K9J6T7ZPdshMGwGA1UdHwRl
# MGMwYaBfoF2GW2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01p
# Y3Jvc29mdCUyMFB1YmxpYyUyMFJTQSUyMFRpbWVzdGFtcGluZyUyMENBJTIwMjAy
# MC5jcmwweQYIKwYBBQUHAQEEbTBrMGkGCCsGAQUFBzAChl1odHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFB1YmxpYyUyMFJT
# QSUyMFRpbWVzdGFtcGluZyUyMENBJTIwMjAyMC5jcnQwDAYDVR0TAQH/BAIwADAW
# BgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwZgYDVR0gBF8w
# XTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMAgGBmeBDAEEAjAN
# BgkqhkiG9w0BAQwFAAOCAgEARDIcwv2XI6Rv81ERO89mKeb61MVI7BOV2t7f9kRr
# xEsL25rJN2yx4UhQGo4KNl0PMaBgz97FISgiz3iAkm5Fb+lfLEqfHyfCaLOsq2sH
# 9mFYrPLXFfjju1PUuiRj0M6Zj53H80HOJ3tX6mePh4immyAxKBXXXUE9hIJJPX88
# QmPxGedmrydu3Un6yPyA5sp/VddDt4kKYNhfgvbzU65O51YKA6B2vfkN6WK9CBxp
# 0preYq4Bk+N+s6OVp1z/BcTIbMB9WosokmYlc4aK9dAvQudnD9wvPzxKDClF7LS4
# 6DztEzJHlv9Ra9fOilw+OUEYAaNMSJoLVk3c1hZ5Q/qe/ogwSLkqzXEVw0WLqv2m
# GWg4VkiNEmHTyFlYeV717lgN9WvKENEjvqD2tzZPNJNPOuMIosidSrG0p2mnn4Pb
# 7KXoIa6WPJYwsMXwlLceR0ETYACTiPCCgAiuHdNeDJNIZUTtJUFUR3oKiINvSul6
# pHN+tFtmSRlHLLZSqJJFY+igB4xsqy0T83qWH4mVCauIF8sW6bym9VydhTduvNml
# KDV6PUckStXIdH+upOvso/PJM77gu/ryVrTQ7P1KSDOh4ZtJFOuCVCezDBEHAHO5
# KX7expu2HkSvqCoKlIGFwn5s21/JyVyWZz2vAA1lbCKrLjQMQiNAmV5FC6H6qOQX
# us8xggPkMIID4AIBATB4MGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwAhMzAAAAWXzacemNXvXAAAAAAABZMA0GCWCGSAFl
# AwQCAgUAoIIBPTAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwPwYJKoZIhvcN
# AQkEMTIEMAO9A8ghDUULkhJs+4Uu1XRIm6AT3+X+iOYnczrT8lGuJXL4aIrc21iy
# w6mq07llljCB3QYLKoZIhvcNAQkQAi8xgc0wgcowgccwgaAEIMtFurHbhumxxcQn
# 4eOP3GtxRXDtHw7LIx9IHZgYrf68MHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQ
# dWJsaWMgUlNBIFRpbWVzdGFtcGluZyBDQSAyMDIwAhMzAAAAWXzacemNXvXAAAAA
# AABZMCIEIOTe8SOcyK08MOCNkbjjB28u2GzuT/b/hGa+c0YXfrIkMA0GCSqGSIb3
# DQEBDAUABIICAJyxi5jsTUC15rn/mdRUoPuahmdhUzB3JXXOqZTQLJYVKSApdGNN
# C0/YlQt3nBQtKK/MglSiCwSB2E1jaJjD+tct3Wqr0Zw59IU/aIsi4OL5mtH5K/rl
# A2cySWVjdyLD9gLB2ygpxkz4CoRzKXwuhOctB9ifaUI8BtRUu9Zq4opqubI9hGRS
# sXp+yNfctdy+Ac8kCy3OhZkBS6LAerMNF6y/mx/5Rww7osvzbH8UUAVr61RdsM+6
# +/EuqxABtbnfNsRkQgzJmSivSd8G1kSY47AQ2WvJjNgyAehA7rjFtC00WbEgRHXG
# SkjqMq2bJoxwbHm5Q1yYZHo02SgsnyOX1uypPJeR0ngiFkvICrikt2VX++edsNsV
# MlxpfLVWHNJaP4tauXt+yY4cW2adf0r3fjR0qRBJo+bVviuxZu0vAEWEtn2MN0hE
# qUX72BsC0APh6RweXaDfofZrbtrwqgQ80A6Elt3Z+RVVfWl4SOA3RmQWkRgB1H5r
# +Q1JTwxioCDCeODemVy98OJe/6jpwk62lfS208VpYivbvcR5/kA712RgAoX2QYEb
# e4ID7HnyDlJRUQ3VxdyEnVwPlO7Jo7/IEx3Vz99kEGOfBHekwXPZ0AJQ+1iCZY6B
# GHr35GZKs4jXAZZGNAGyrtAswvYYUaGdgQWPUJS446Hjcdb7zCf9Wh6a
# SIG # End signature block
