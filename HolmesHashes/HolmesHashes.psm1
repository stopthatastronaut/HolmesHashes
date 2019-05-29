Function Get-HolmesHash
{
    [CmdletBinding()]
    param(
        [Switch]$RandomSubParagraph
    )
    # http://blogs.technet.com/b/pstips/archive/2014/06/10/dynamic-validateset-in-a-dynamic-parameter.aspx
    DynamicParam {
        # the 'Book' dynamic param
        $books = new-object System.Management.Automation.ParameterAttribute
        $books.Mandatory = $true
        $books.Position = 0

        $booksColl = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $booksColl.Add($books)

        # where is this module? we need its index file
        $installedModules =  Get-Module -ListAvailable HolmesHashes
        $latest = $installedModules | Sort-Object Version -Descending | Select-Object -first 1
        $f = $latest.ModuleBase
        $indexfile = resolve-path "$f\index.json"
        $index = Get-Content $indexfile -raw | ConvertFrom-Json

        $bookSet = [string[]]($index | Select-Object -expand Tome)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($bookSet)
        $booksColl.Add($ValidateSetAttribute)

        $bookParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("Book", [string], $booksColl)
        $bookParam.Name = "Book"

        $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("Book", $bookParam)

        # the algorithm dynamic param
        $algo = new-object System.Management.Automation.ParameterAttribute
        $algo.Mandatory = $false
        $algo.ParameterSetName = "__AllParameterSets"
        $algo.Position = 1

        $algoColl = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $algoColl.Add($books)

        $algorithms = Get-Command Get-FileHash
        $algoValues = $algorithms.Parameters["algorithm"].Attributes | Where-Object { $null -ne $_.ValidValues }
        $validAlgorithms = $algoValues.ValidValues

        $ValidateSetAttribute2 = New-Object System.Management.Automation.ValidateSetAttribute($validAlgorithms)
        $algoColl.Add($ValidateSetAttribute2)

        $algoParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("Algorithm", [string], $algoColl)
        $algoParam.Value = "SHA1"
        $algoParam.Name = "Algorithm"

        $paramDictionary.Add("Algorithm", $algoParam)

        return $paramDictionary
    }

    begin {
        $out = @()
    }
    process {
        if($null -eq $psboundparameters.algorithm) {
            $algorithm = "SHA1"
        }   else {
            $algorithm = $psboundparameters.algorithm
        }
        Write-Verbose "Obtaining book $($psboundparameters.book)"
        $tmp = "$env:tmp/HolmesHashTemp.txt"
        # chuck the contents, filtered if necessary, into a temporary file. Hash it.

        $bookcontent = Get-BookText -book $psboundparameters.book
        $bookContent | Out-File $tmp
        $hash = Get-FileHash -Path $tmp -Algorithm $algorithm


        $out += [pscustomobject]@{
            Book = $PSBoundParameters.Book;
            Hash = $hash.Hash;
            Text = $bookcontent;
            Algorithm = $Algorithm;
        }

    }
    end {
        return $out
    }
}

Function Get-BookText
{
    param($book) # Let's not quibble about the difference between a "Story", a "Novel" and a "Collection". Everything is a book.

    $bookfile = Get-BookFile $book
    if($null -eq $bookfile)
    {
        throw "Book $book not found in index"
    }
    if(-not (Test-Path $bookfile))
    {
        throw "Book file not found $bookfile"
    }

    return (Get-Content $bookFile -raw)
}

Function Get-BookFile
{
    param($book)
    $index = Get-HolmesIndex
    $f = Get-ModuleBase
    $bookfile = $index | Where-Object { $_.Tome -eq $book } | Select-Object -expand File
    return "$f\books\$bookfile"
}

Function Get-ModuleBase # are we loading from a module base, or as a script while not installed (as in testing)
{
    $installedModules =  Get-Module -ListAvailable HolmesHashes
    $latest = $installedModules | Sort-Object Version -Descending | Select-Object -first 1
    if($null -ne $latest.ModuleBase) {
        return $latest.ModuleBase
    }
    else {
        $modulePath = Split-Path $PSCommandPath -Parent
        return $modulePath
    }
}

Function Get-HolmesIndex
{
    $f = Get-ModuleBase
    $indexfile = resolve-path "$f\index.json"
    $index = Get-Content $indexfile -raw | ConvertFrom-Json
    return $index
}

Function Get-SubParagraph
{
    param($bookid)
}
