Set-Location -Path $PSScriptRoot
# Define the path to your JSON file
$jsonFilePath = ".\neos-t1452-eh-test-Json-quotes.json"

# Load JSON data from the file
$jsonContent = Get-Content -Path $jsonFilePath #-Raw
$pattern = '\{([^{}]*)\}'
$jsonSections = [regex]::Matches($jsonContent, $pattern)

# Function to split content by colon
function Split-ContentByColon {
    param (
        [string]$content
    )
    
    # Split content by colon
    $parts = $content -split ':',2
    return $parts
}
# Output all matches
Foreach ($jsonLine in $jsonSections) {
    $contentInsideBraces = $jsonLine.Groups[1].Value
     $splitContent = Split-ContentByColon -content $contentInsideBraces
    ForEach($jContent in $splitContent){        
        #$pattern2 = '^"(.*)"$'  
        $matchesJContent = [regex]::Matches($jContent.Trim(), '^"(.*)"$')
        If($matchesJContent.Count -gt 0){
            ForEach($match in $matchesJContent)
            {
                $jsonContent = $jsonContent -replace $match.Groups[1].Value, $match.Groups[1].Value.Replace('"','\"')
                
            }
        }
        
    }
         
}
Write-Output $jsonContent