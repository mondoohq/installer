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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAm4dX/1
# 4x6WFgvHAAAACbh1MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQwHhcNMjYxMTExMDI1MDI0WhcNMjYxMTE0
# MDI1MDI0WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAtZbO
# NDygzYZUrRm3IApiqVW3a2zVPTW2SCHvRP+GqNAvMe3vpmHMicWLr0F4jmDGvXxc
# G2puDqEv1CKA02+7KE67WgfzGvi0ZOn73EnRXX/m5So4tdCpVdvRO3GTRbUEDCy1
# yyU8WKyD/qF4X4MV2R+bZxf+yabIwmrJ0FZ5Nr/IEBsarkMY/3hCDiWq7DVcb81F
# jTGA1GJ99uyjeTIMNEi1h7f0CCmIJRMBwRPU/RvqadKZK7WX5fuYnKi+TmYKFLjV
# zh90KPtHozalN4nfXIbpmEHwHL8azz1t+7QuysFKfeuG+YStAhECJxhmZdB5ue9J
# 8ykp5XkKrnRv0Bzpzx4dhILUcr62Dyn35IiNggVEGMYmn8weiegfljTijgk2ByEG
# tq1D2DyeXWeRR38puUc/FvHE0NAEgbiDM0RBNEzA6aHuxteS+RbsmsGiNdsQtGqZ
# +PORKph0dQETkzrRlqFDKCYexAYwwevOmSkiVc1v3FkzmUwG4KKX1yJAyf/BAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUBHa3ZaqV74IFQxXgUoFbFk5a7q4wHwYDVR0jBBgw
# FoAUmvFUd3UMhxY3RqCs3nn59H/BeOkwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwNC5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBACaGhEG+ecjJSeyU1Nc4TOmeVzFM5Mz3Y1lVrb/6v6el
# wVg4vzDvHEfC3CR8uYV5iJlUbf6sObu5/0nAM/CcIfNYwBhfplw1fNrtMWJSbMtc
# FlOdZMzhKGL6XVKwQMSzH5+yZBHdy+A6YpJIjTwSjHMAOlRnsezCmMCFnB74TYYA
# TNT7JaAxrQi72VpaiqGcw6iNS0MnymROHAvfhxrY/6b9qKsHaAupCa/swkD492ky
# VOjGq/7Q4+3JnG1lW3kxMsg1mc4JTkG8czsrvZgpnV8Nifo3RHom6nL++UOJB/GB
# JXk/GvhIzzhmPGU6TVe14Yo0w+kQTi3rejepZIIZAmFBaaSIcClSwyHOI9Jr0h6b
# aAKKIWvKciL6UjpQJ2hhsMW8Af6khkfQ0wnRhg6IhEu1R+ShACTzdGQGaWKtyi6b
# 3V1XZBm7E+Oo8ylAkmTwes+MJABgj1xO14IVKX166A6CmuCImQzCzACoSVgndm9u
# nJ+tJfInUaBbpo+6H9P4BsnE4/ANzBJSodIlFDkqsKTXJestrzhn1GmsNInkQBRR
# E2NJsMsmzGlTFrX9Fvmt/3otdF7tapYmQefkdJO+WHmiLPEjTqvhcJKQE/4asQ8t
# Eh1VfUWM6w7JvAsbOmjfvoOIN4YztuNb8tF89VSOYKC8mgrlfGL4bE3MrO29Gzkv
# MIIGojCCBIqgAwIBAgITMwAJuHV/9eMelhYLxwAAAAm4dTANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDA0MB4X
# DTI2MTExMTAyNTAyNFoXDTI2MTExNDAyNTAyNFowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBALWWzjQ8oM2GVK0ZtyAKYqlVt2ts1T01tkgh70T/
# hqjQLzHt76ZhzInFi69BeI5gxr18XBtqbg6hL9QigNNvuyhOu1oH8xr4tGTp+9xJ
# 0V1/5uUqOLXQqVXb0Ttxk0W1BAwstcslPFisg/6heF+DFdkfm2cX/smmyMJqydBW
# eTa/yBAbGq5DGP94Qg4lquw1XG/NRY0xgNRiffbso3kyDDRItYe39AgpiCUTAcET
# 1P0b6mnSmSu1l+X7mJyovk5mChS41c4fdCj7R6M2pTeJ31yG6ZhB8By/Gs89bfu0
# LsrBSn3rhvmErQIRAicYZmXQebnvSfMpKeV5Cq50b9Ac6c8eHYSC1HK+tg8p9+SI
# jYIFRBjGJp/MHonoH5Y04o4JNgchBratQ9g8nl1nkUd/KblHPxbxxNDQBIG4gzNE
# QTRMwOmh7sbXkvkW7JrBojXbELRqmfjzkSqYdHUBE5M60ZahQygmHsQGMMHrzpkp
# IlXNb9xZM5lMBuCil9ciQMn/wQIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFAR2t2Wqle+C
# BUMV4FKBWxZOWu6uMB8GA1UdIwQYMBaAFJrxVHd1DIcWN0agrN55+fR/wXjpMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDA0LmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQAmhoRBvnnIyUns
# lNTXOEzpnlcxTOTM92NZVa2/+r+npcFYOL8w7xxHwtwkfLmFeYiZVG3+rDm7uf9J
# wDPwnCHzWMAYX6ZcNXza7TFiUmzLXBZTnWTM4Shi+l1SsEDEsx+fsmQR3cvgOmKS
# SI08EoxzADpUZ7HswpjAhZwe+E2GAEzU+yWgMa0Iu9laWoqhnMOojUtDJ8pkThwL
# 34ca2P+m/airB2gLqQmv7MJA+PdpMlToxqv+0OPtyZxtZVt5MTLINZnOCU5BvHM7
# K72YKZ1fDYn6N0R6Jupy/vlDiQfxgSV5Pxr4SM84ZjxlOk1XteGKNMPpEE4t63o3
# qWSCGQJhQWmkiHApUsMhziPSa9Iem2gCiiFrynIi+lI6UCdoYbDFvAH+pIZH0NMJ
# 0YYOiIRLtUfkoQAk83RkBmlircoum91dV2QZuxPjqPMpQJJk8HrPjCQAYI9cTteC
# FSl9eugOgprgiJkMwswAqElYJ3ZvbpyfrSXyJ1GgW6aPuh/T+AbJxOPwDcwSUqHS
# JRQ5KrCk1yXrLa84Z9RprDSJ5EAUURNjSbDLJsxpUxa1/Rb5rf96LXRe7WqWJkHn
# 5HSTvlh5oizxI06r4XCSkBP+GrEPLRIdVX1FjOsOybwLGzpo376DiDeGM7bjW/LR
# fPVUjmCgvJoK5Xxi+GxNzKztvRs5LzCCBygwggUQoAMCAQICEzMAAAAXJ0UJC4uH
# r8YAAAAAABcwDQYJKoZIhvcNAQEMBQAwYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZl
# cmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTAeFw0yNjAzMjYxODExMzFaFw0z
# MTAzMjYxODExMzFaMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBF
# T0MgQ0EgMDQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCCx2T+Aw9m
# KgGVzJ+Tq0PMn49G3itIsYpbx7ClLSRHFe1RELdPcZ1sIqWOhsSfy6yyqEapClGH
# 9Je9FXA1cQgZvvpQbkg+QInVLr/0EPrVBCwrM96lbRI2PxNeCwXG9LsyW2hG6KQg
# intDmNCBo4zpDIr377plVdSliZm6UB7rHwmvBnR02QT6tnrqWq2ihzB6lRJVTEzu
# h0OafzIMeMnYM0+x+ve5EOLHdfiq+HXiMf9Jb7YLHtYgyHIiJA7bTWLqFSLGaTh7
# ZlbxbsLXA91OOroEpv7OjzFuu3tkpC9FflA4Dp2Euq4+qPmxUqfGp+TX0gLRJp9N
# JOzzILjcTD3rkFFFbxUv1xyg6avivFDLtoKBhM2Td138umE1pNOacanuSYtPHIeQ
# HmB6haFi64avLBLwTTAm/Rbit860cFXR72wq+5Qh4hSmezHqKXERWPpVBe+APrJ4
# Iqc+aPeMmIkoCWZQO22HnLNFUFSXjiwyIbgvlH/LIAJEqTafTzxDZgKhlLU7zr6g
# wsq3WNpcYQI6NuxWnwh3VVDDyF7onQqKs5Ll7bleVN0Y8VvqgE45ppyBbvwqN/Ru
# n5fMCCRz3aYMY0kZhKO92eP7t4zHqZ5bQMAgZ0tE2Pz/jb0wiykUF/PcoOqqk3vV
# LiRDYst6vd3GEMNzMpUUvQcvBG46+COIbwIDAQABo4IB3DCCAdgwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBSa8VR3dQyHFjdGoKze
# efn0f8F46TBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBkG
# CSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYD
# VR0jBBgwFoAU2UEpsA8PY2zvadf1zSmepEhqMOYwcAYDVR0fBGkwZzBloGOgYYZf
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# SUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyMS5jcmww
# fQYIKwYBBQUHAQEEcTBvMG0GCCsGAQUFBzAChmFodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3J0MA0GCSqGSIb3DQEBDAUAA4IC
# AQCQdVoZ/U0m38l2iKaZFlsxavptpoOLyaR1a9ZK2TSF1kOnFJhMDse6KkCgsveo
# iEjXTVc6Xt86IKHn76Nk5qZB0BXv2iMRQ2giAJmYvZcmstoZqfB2M3Kd5wnJhUJO
# tF/b6HsqSelY6nhrF06zor1lDmDQixBZcLB9zR1+RKQso1jekNxYuUk+HaN3k1S5
# 7qk0O//YbkwU0mELCW04N5vICMZx5T5c7Nq/7uLvbVhCdD7f2bZpA4U7vOkB1ooB
# 4AaER3pjoJ0Mad5LFyi6Na9p9Zu/hrLeOjU5FItS5YxsqvlfXxAThJ176CmkYstK
# RmytSHZ7JhKRfV6e9Zftk/ODb/CK4pGVAVqsOf4337bQGrOHHCQ3IvN9gmnUuDh8
# JdvbheoWPHxIN1GB5sUiY584tXN7xdD8LCSsRqJvQ8e7a3gZWTgViugRs1QWq+N0
# G9Nje6JHlN1CjJehge+H5PGktJja+juGEr0P+ukSkcL6qaZxFQTh3SDI71lvW++3
# bl/Ezd6SO8N9Udw+reoyvRHCyTiSsplZQSBTVJdPmo3qCpGuyHFtPo5CBn3/FPTi
# qJd3M9BHoqKd0G9Kmg6fGcAvFwnLNXA2kov727wRljL3ypfqL7iAT/Ynpxul6RwH
# RlcOf9dDGg1RRvr92NP/CWVXIb68geR2rvU/NsfmtjF1wDCCB54wggWGoAMCAQIC
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
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQCEzMACbh1f/XjHpYWC8cAAAAJ
# uHUwDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgr4zOdXS8ZgUgCkJAq4tC
# JvEPPleACIt7sM/BkafCe/EwDQYJKoZIhvcNAQEBBQAEggGARzwyCei4kAPBQZ52
# 6FfcKe8xallM1bYO1Q+7G0FYJKNL+pOB3wTNfSLuc9pDVevKBWBjQytTGiRMahut
# TaxTEll4N8rpSFswyRidxf8sFC7GBfUgBXiVQZPUBpEzbqqVzr8yzj+trBforulA
# VSBak79bCplFLYt0WAr4H3sfoDIskICO9mqoQ4sE+KNQaEPxcB6E5qler1XFcR7w
# kNKZQ99z59CHfXx0SFA4FsTCk+rOKjfecsV3EiKgBdD0LWZ+byQG1ot92BoOpl4y
# cQ5eyDGfqHOTiMiHZZwe8TK5auKr9jLLc4k0Sb2DibyBc6IstSSO7LZkh9OGuguP
# JOC4kyRni/B/kQ6CmoWcLrtyn4ktd3jKmF9Gum9E/R96ZRIJl2pu/0NTZiW61gfH
# bcL6SAa8U4GRH/4HZxN2eE5LjqR1nJaxeSdXYeRvFGc+ANt5OL+wnXenZ4n8pUQJ
# l2HFKXL9EEUvoW6B+1zeZFJIMK6ayVfhE1t3K0mIy7aCroZOoYIYMTCCGC0GCisG
# AQQBgjcDAwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMJ5AzOVtQ70S0mX/tqU3eGolTnp6QsQGDeud
# KcaotOjnzhr638FF8BIqv5TcFX+yAAIGavNL+tslGBMyMDI2MTExMjIyNTc1Ni43
# NThaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
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
# blyNhrGcl2NSh4QpwBpPKeLXeCSLgyFbaukaAV4QJdIAFjGCB1MwggdPAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABgcgYkikoFuNkAAAAAAGAwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MTExMjIyNTc1NlowPwYJKoZIhvcNAQkEMTIEMKEsa0MKbGDf
# oA5IKPizx7MXQUws0QA+37wqDDbXKoIy80f/m9cfbSWvHXRKLRayYjCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEIDfLjLnwvS54utKqPKxmcYlH7Orna0xc019M
# pXpStgKzMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAYHIGJIpKBbjZAAAAAABgMIIDXgYLKoZIhvcN
# AQkQAhIxggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpB
# NTAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAJe/M8jCvUlk8+It
# Y60JUWKjdUI3oGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7qBteDAiGA8yMDI2
# MTExMjE2NTMxMloYDzIwMjYxMTEzMTY1MzEyWjB0MDoGCisGAQQBhFkKBAExLDAq
# MAoCBQDuoG14AgEAMAcCAQACAgR1MAcCAQACAhMXMAoCBQDuob74AgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
# hqAwDQYJKoZIhvcNAQELBQADggEBAFmG59Nb0ka9pPubcsB+rVOjR1MlT7qaPiQ3
# lEFIrRDvH5wEGtez0cn5JyYKTSf9ibmq068MAMXrwEEdsyd10Fwge3rohzKgSJpS
# n/Wx7BVf2BnYpVwWq3vfZT1y97b8x4SOPSOvOzsPM+olUStYuRxERBynHEBfefDV
# Rgdlw4YOqefDgmWlZ8yVpKGSUFLg0rT2AHfK/TQ+BgTaTAw6KGXyMz6mjLX8Abii
# xsflcRSd2Vwrc3Nsgbc0Z1vfIX8Z26S/bQjCUnZWiJl4M5OFfkzCLng1TTmPD49e
# QeJ9fqG66pUPhn5Q5x5Dm8AVByB+lZalaNR096oxW8Oon3RsBeIwDQYJKoZIhvcN
# AQEBBQAEggIAO5uG4IwLma/K5cC6AnYbadZIyPRAXJEv86H9nuDy3U271bTOq4yg
# So5SIXCgAq+rWyGm6j7VMlDl9rALsna5mPvzV+EjwK5VEF40jlXci2g9W0SQs3/q
# 36ko6C7sJmOBAx+GKRj2HNBJkuUO4VUlRm0s/MUcTraHlCaJhtYjqv+JDsq7sGTW
# EBIyBQvJRFy/ULpZbUvr4Skc/6MPskYhg/xHpK+m+R2iPFYmVg1mxpcxhg1W9OIo
# kFLA4INbeysz+dfBpeIF+WVua/cxxCfexJMW3g2RJ01YvtQBJZajsOTax6wp/44A
# ioUibzCLwoCv8dwJwvKlWlg9VUpNoL7oZug9UVZdYwlWE2+gK6CuiEHexMhRdS7D
# fQlMnoh7vx8Ej4I2wmsHnOQFs0VNCZ8KUtjS4JTOW6QZKZy3XvwwcH8SNwaD0MJv
# ED9EmkI/XdwHIg4h1svd3cBMyaLFfg66YGhuPfCpexi0YoFSp8Oplb3o102AEv6i
# xuW2pGVMwOrIInin/8amQmiOX9t3dvfEpQeTMwCKMn3HDodnhwd4g83gBaTTKj0k
# yg70Zvq6zIrL+MInwf8WxMWRCTWNh8pZ8SC1jI87fldecGeQtPhA+lmXur/asxO4
# p8KxfextNAf9sBhbdhrfQWYyLrweLXI8DY4uKzaBdrDxr9HEVa2y9DE=
# SIG # End signature block
