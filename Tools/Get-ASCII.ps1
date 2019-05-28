# Gets all the ASCII texts from https://sherlock-holm.es/ascii/

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

$source = iwr https://sherlock-holm.es/ascii/

$usexclusion = @( # files that are not us-friendly
    'The Complete Canon',
    'The Illustrious Client',
    'The Blanched Soldier',
    'The Mazarin Stone',
    'The Three Gables',
    'The Sussex Vampire',
    'The Three Garridebs',
    'Thor Bridge',
    'The Creeping Man',
    "The Lion`'s Mane",
    'The Veiled Lodger',
    'Shoscombe Old Place',
    'The Retired Colourman',
    'The Case-Book of Sherlock Holmes'
)

$ascii = $source.Links | ? { $_.href -like "*/plain-text/*" -and $_.InnerText -notin $usexclusion }

$index = @()

$ascii | % {
    $rel = $_.href
    $rels = $rel -replace "/stories/plain-text/", ""
    iwr "https://sherlock-holm.es$rel" -OutFile ("../HolmesHashes/books/$rels") -verbose
    $title = $_.InnerText
    if($rels -eq "lstb.txt")
    {
        # special case. His Last Bow is both a collection and a standalone story. Disambiguate
        $title = "His Last Bow (Collection)"
    }

    $index += [pscustomobject]@{ Tome = $title; File = $rels }
}

# save the index

$index | ConvertTo-Json | Out-File "../HolmesHashes/index.json"
