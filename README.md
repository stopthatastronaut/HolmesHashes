# HolmesHashes - Elementary dummy hashes, my dear Watson

I had a need to generate some "random" SHA hashes, for testing purposes - hashes that were in no way related to actual production data. I figured there were worse ways to do this than to use the copyright-free text of the Sherlock Holmes canon.

Which led to me writing this Module. While doing so, I got to play with PowerShell dynamic parameters and some other little features.

# On Copyright

This repo does not include the full canon, because of weird US Copyright laws. You'll just have to do without the Casebook.

The source text was obtained from [The Complete Sherlock Holmes Canon](https://sherlock-holm.es/ascii/). It is possible, if you're outside the US, to plug in the full canon. See the [Tools](Tools/) folder

# how to use

```
Install-Module HolmesHashes
Import-Module HolmesHashes
Get-HolmesHash -Book "The Hound of The Baskervilles" -Algorithm SHA1
```
