if(Get-Module HolmesHashes)
{
    Remove-Module HolmesHashes
}

Import-Module .\HolmesHashes\HolmesHashes.psm1

$settings = @{
    Rules = @{
        PSUseCompatibleSyntax = @{
            # This turns the rule on (setting it to false will turn it off)
            Enable = $true
            # List the targeted versions of PowerShell here
            TargetVersions = @(
                '3.0',
                '4.0',
                '5.1',
                '6.2'
            )
        }
    }
}
Describe "PSScriptAnalyzer" {
    Import-Module PSScriptAnalyzer
    $excludedRules = @(
        # 'PSUseShouldProcessForStateChangingFunctions'
    )

    $path = Resolve-Path "./HolmesHashes"
    Write-Output "Running PsScriptAnalyzer against $path"
    $results = @(Invoke-ScriptAnalyzer $path -recurse -exclude $excludedRules -settings $settings)
    $results | ConvertTo-Json | Out-File PsScriptAnalyzer.log

    It "Should have zero PSScriptAnalyzer issues in Module" {
        $results.length | Should Be 0
    }
}

InModuleScope HolmesHashes {

    Describe "Get-HolmesIndex" {
        It "Should not Throw" {
            { Get-HolmesIndex } | Should Not Throw
        }

        It "Should return an object, not a string" {
            (Get-HolmesIndex).getType().Name | Should Be "Object[]"
            (Get-HolmesIndex) -is [Object[]] | Should Be $true
        }

        It "Should have properties 'Tome' and 'File'" {
            Get-HolmesIndex | Get-Member | ? { $_.Name -eq "Tome"} | Should Not Be $null
            Get-HolmesIndex | Get-Member | ? { $_.Name -eq "File"} | Should Not Be $null
        }

        It "Should probably have The Hound in it" {
            Get-HolmesIndex | ? {$_.Tome -like "The Hound*"} | Should Not Be $null
        }

        It "Should not contain the case-book" { # because copyright
            Get-HolmesIndex | ? { $_.Tome -like "*Case-book of*"} | Should Be $null
        }
    }

    Describe "Get-BookText" {
        It "Should not Throw" {
            # pick a random book from the index
            {
                $book = Get-HolmesIndex | Get-Random | Select-Object -expand Tome
                Get-BookText $book } | Should Not Throw
        }

        It "Should contain distinct phrases" {
            Get-BookText -book "The Final Problem" | Should Match "Aye, there's the genius and the wonder of the thing!"
            Get-BookText -book "The Dying Detective" | Should Match "Such a remark is unworthy of you, Holmes"
            Get-BookText -book "The Hound of The Baskervilles" | Should Match "I have, at least, a well-polished, silver-plated coffee-pot"
        }
    }

    DEscribe "Get-BookFile" { # return a file path in exchange for a book name
        It "Should know where to find His Last Bow" { # not the compilation
            Get-BookFile -book "His Last Bow" | Should BeLike "*last.txt"
            Test-Path (Get-BookFile -book "His Last Bow") | Should Be $true
        }
    }

    Describe "Get-HolmesHash" {
        $book = "The Return of Sherlock Holmes"
        $splat = @{Book = $book; Algorithm = "SHA1";}
        It "Should not Throw" {
            { Get-HolmesHash -book $book -Algorithm SHA1 } | Should Not Throw
        }

        It "Should return an object, not a string" {
            (Get-HolmesHash -book $book -Algorithm SHA1).getType().Name | Should Be "PSCustomObject"
            (Get-HolmesHash -book $book -Algorithm SHA1) -is [PSCustomObject] | Should Be $true
        }

        It "Should have properties 'Hash' and 'Text', 'Book' and 'Algorithm'" {
            Get-HolmesHash @splat | Get-Member | ? { $_.Name -eq "Hash"} | Should Not Be $null
            Get-HolmesHash @splat | Get-Member | ? { $_.Name -eq "Text"} | Should Not Be $null
            Get-HolmesHash @splat | Get-Member | ? { $_.Name -eq "Book"} | Should Not Be $null
            Get-HolmesHash @splat | Get-Member | ? { $_.Name -eq "Algorithm"} | Should Not Be $null
        }

        Context "With known hashes" {
            It "Should return the correct Hash" {
                Get-HolmesHash -book "A Study In Scarlet" -Algorithm SHA1 | Select-Object -expand Hash | Should Be "896099EBB4176C703A9970CDB0BBEDCB9A2838EE"
            }
        }
    }


}
