#ok - we are reading 3 times and accidentally wrapping back around to the beginning of the file to fill our Buffer.
# Need to stop at file end and calc md5 there on last loop.
# Subtract Buffer size from file size and update Buffer to be remainder if size less than original Buffer. :) :) :)
# https://stackoverflow.com/questions/10521061/how-to-get-an-md5-checksum-in-powershell



### do we need to keep the hash as bytes, and then hash the 3 sets of bytes? ------ yes

# https://teppen.io/2018/10/23/aws_s3_verify_etags/
# https://teppen.io/2018/06/23/aws_s3_etags/

# derive number of parts from etag
# reconstruct etag with "-$NumParts" and compare
# clean up this POS and rename variables and function
# Add s3api PUT b64 Content-MD5 calculation

# sonofabitch. S3 console part size = 17179870 bytes. WHY?????!?!?!?
# 17MB (exact) file upload via console is split in 2 parts
# Content-Length: 17179870
# Content-Length: 645922
# 17179870 + 645922 = 17825792 (17MB)
# 17179870 = 16.384 and change MB in binary. Hmm.
# 160GB console max = 171,798,691,840 B (binary) - rounded to 171,798,700,000 to give 10,000 part maximum at a part size of 17,179,870 (160.00000 and some change gibibytes - calc screenshot)


# Would be nice to return an object with hash byte arr, b64 and md5str for each chunk
# Also return md5str with - and parts

function Confirm-S3ETag {  
[CmdletBinding()]
Param(
    [Parameter(HelpMessage="Specify the GitHub URL of the AWS CLI release page")]
    [ValidateNotNullOrEmpty()]$GitHubURL = "https://github.com/aws/aws-cli/releases",
    
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_ })]$Path,

    [Parameter(HelpMessage="Specify the part size in bytes or MB by which the file will be processed")]
    [ValidateSet("1MB","1048576","8MB","8388608","17179870")][Int32]$PartSizeBytes = 8MB,
    
    [Parameter(HelpMessage="Specify an existing ETag to validate against")]
    [String]$ReferenceS3ETag
    )

    
        $MD5Arr = New-Object System.Collections.ArrayList
        $File = New-Object System.IO.FileInfo($Path)
        $TotalParts = [int][Math]::Ceiling($File.Length / $PartSizeBytes)
        Write-Verbose "Total parts $($TotalParts)"
        $reader = [IO.File]::OpenRead($Path)

        [int]$FilesizeCounter = $File.Length
        Write-Verbose "File size $($FilesizeCounter)"
        # read parts until there is no more data
For ($i=1; $i -le $TotalParts; $i++) {
  
            # read a chunk
            $Buffer = New-Object Byte[] $PartSizeBytes
            $BytesRead = $reader.Read($Buffer, 0, $Buffer.Length)
            Write-Verbose "$($BytesRead) bytes read"
            $FilesizeCounter = $FilesizeCounter - $BytesRead
            Write-Verbose "Remaining bytes to be read $($FilesizeCounter)"
            
            $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            $global:HashPart = $MD5.ComputeHash($Buffer) #Hash the raw bytes - don't make it a string
            Write-Verbose "$($HashPart)"
            $Base64String = [System.Convert]::ToBase64String($HashPart)
            
            $hashstr = [System.BitConverter]::ToString($MD5.ComputeHash($Buffer)) ################ file under chunk size
            $hashstr = $hashstr.replace('-','').ToLower()                         ################ file under chunk size
            Write-Verbose "hashstr $($hashstr)"
            Write-Verbose "$($Base64String)"
            [void]$MD5Arr.Add($HashPart)

            If ($Filesizecounter -lt $PartSizeBytes) {
                $PartsizeBytes = $FileSizeCounter
            }
            
            $Buffer = $null
 
            Write-Verbose "Loop $i of $TotalParts"

}
        $arr = foreach ($item in $MD5Arr) {
                $item
            }
            $global:hashzzz = [System.BitConverter]::ToString($MD5.ComputeHash($arr)) #only during multipart? - yes.
            $Hashzzz = $Hashzzz.replace('-','').ToLower()
        $Reader.Close()

    Return $hashzzz
} #End Confirm-S3ETag

<#
PS C:\Users\tapple> Split-File "C:\Users\tapple\Downloads\AWSCLI64PY3.msi" -Verbose
VERBOSE: File size 22568960
VERBOSE: 8388608 bytes read
VERBOSE: Remaining bytes to be read 14180352
VERBOSE: A5EA029026FC1B20BC36AD7CA6363057
VERBOSE: 8388608 bytes read
VERBOSE: Remaining bytes to be read 5791744
VERBOSE: 35532E519CD7B03195D1A231934E1345
VERBOSE: 5791744 bytes read
VERBOSE: Remaining bytes to be read 0
VERBOSE: CB1C0E249B8331939B4047B0D155831A

PS C:\Users\tapple\Documents\Projects\Other PowerShell> aws s3api head-object --bucket aws-cli --key AWSCLI64PY3.msi
{
    "AcceptRanges": "bytes",
    "LastModified": "Tue, 04 Feb 2020 20:18:42 GMT",
    "ContentLength": 22568960,
    "ETag": "\"1bc008aacaac3366da6fc0abeff024c7-3\"",
    "ContentType": "application/x-msi",
    "Metadata": {}
}



[b'a5ea0290&fc1b bc6ad|a660W', b'5S.Q9cd7b0195d1a2193N13E', b'cb1c0e$9b831939b@Gb0d1U831a']

b'\xa5\xea\x02\x90&\xfc\x1b \xbc6\xad|\xa660W'
b'5S.Q\x9c\xd7\xb01\x95\xd1\xa21\x93N\x13E'
b'\xcb\x1c\x0e$\x9b\x831\x93\x9b@G\xb0\xd1U\x83\x1a'

a5ea029026fc1b20bc36ad7ca6363057
35532e519cd7b03195d1a231934e1345
cb1c0e249b8331939b4047b0d155831a

tapple@SEA-1800438495:~$ python3 etag-verify.py AWSCLI64PY3.msi 1bc008aacaac3366da6fc0abeff024c7-3
22568960 3
8388608
a5ea029026fc1b20bc36ad7ca6363057
35532e519cd7b03195d1a231934e1345
cb1c0e249b8331939b4047b0d155831a
1bc008aacaac3366da6fc0abeff024c7-3
Local file matches

>>> md5(b''.join(md5_digests)).hexdigest()
'1bc008aacaac3366da6fc0abeff024c7'

>>> md5(b''.join(md5_digests)).digest()
b'\x1b\xc0\x08\xaa\xca\xac3f\xdao\xc0\xab\xef\xf0$\xc7'

>>> import binascii
>>> a = binascii.hexlify(bin)
>>> a
b'1bc008aacaac3366da6fc0abeff024c7'

#>


<#

so if the file is less than the chunk size, use file size as chunk size.

PS C:\Users\tapple> $Path = C:\Users\tapple\small-1MB-file.bin
PS C:\Users\tapple> $Path = 'C:\Users\tapple\small-1MB-file.bin'
PS C:\Users\tapple> $reader = [IO.File]::OpenRead($Path)
PS C:\Users\tapple> $reader


CanRead        : True
CanWrite       : False
CanSeek        : True
IsAsync        : False
Length         : 1048576
Name           : C:\Users\tapple\small-1MB-file.bin
Position       : 0
Handle         : 3124
SafeFileHandle : Microsoft.Win32.SafeHandles.SafeFileHandle
CanTimeout     : False
ReadTimeout    :
WriteTimeout   :



PS C:\Users\tapple> $Buffer = New-Object Byte[] $reader.Length
PS C:\Users\tapple> $BytesRead = $reader.Read($Buffer, 0, $Buffer.Length)
PS C:\Users\tapple> $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
PS C:\Users\tapple> $HashPart = $MD5.ComputeHash($Buffer)
PS C:\Users\tapple> $HashPart
182
216
27
54
10
86
114
216
12
39
67
15
57
21
62
44
PS C:\Users\tapple> $Base64String = [System.Convert]::ToBase64String($HashPart)
PS C:\Users\tapple> $Base64String
ttgbNgpWctgMJ0MPORU+LA==
PS C:\Users\tapple>

#>
