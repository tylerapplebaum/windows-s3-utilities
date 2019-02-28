#https://docs.aws.amazon.com/powershell/latest/userguide/specifying-your-aws-credentials.html

#### Need to write subfolders as keys first, then upload data. Make 2 functions, one for subfolders, one for just files.

If ($(Get-Module -Name AWSPowerShell -Verbose) -eq $null) {
    Write-Error "AWSPowerShell module not found; aborting"
}

Function Sync-FilesToS3 {
[CmdletBinding()]
  param(
  [Parameter(HelpMessage="Specify the S3 bucket to write to")]
  [ValidateNotNullOrEmpty()]
  [string]$BucketName,
  
  [Parameter(HelpMessage="Specify the AWS API user profile name")]
  [ValidateNotNullOrEmpty()]
  [string]$ProfileName,
  
  [Parameter(HelpMessage="Specify the path to the source files to copy to S3")]
  [ValidateNotNullOrEmpty()]
  [string]$SourcePath
  )
    If (Test-S3Bucket -BucketName $BucketName -ProfileName $ProfileName) {
        Write-Verbose "S3 bucket $BucketName exists"
    }
    Else {
        Write-Error "S3 bucket $BucketName not found"
        Exit
    }
    $SourceFiles = Get-ChildItem $SourcePath
    $i = 0
    ForEach ($File in $SourceFiles) {
        $i++
        $Percentage = "{0:N2}" -f (($i / $SourceFiles.Count) * 100)
        Write-Progress -Activity "Syncing files to S3" -Status "Syncing $File to $BucketName" -PercentComplete $Percentage
        Write-S3Object -BucketName $BucketName -File $File.FullName
    } #End ForEach
    
} #End Sync-FilesToS3



Function Sync-FilesandFoldersToS3 {
[CmdletBinding()]
  param(
  [Parameter(HelpMessage="Specify the S3 bucket to write to")]
  [ValidateNotNullOrEmpty()]
  [string]$BucketName,
  
  [Parameter(HelpMessage="Specify the AWS API user profile name")]
  [ValidateNotNullOrEmpty()]
  [string]$ProfileName
  )
    If (Test-S3Bucket -BucketName $BucketName -ProfileName $ProfileName) {
        Write-Verbose "S3 bucket $BucketName exists"
    }
    Else {
        Write-Error "S3 bucket $BucketName not found"
        Exit
    }
    
}