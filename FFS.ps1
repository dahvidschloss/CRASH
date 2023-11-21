# Name: FakeFileShare (FFS.ps1)
# Author: Dahvid Schloss
# Email: dahvid.schloss@echeloncyber.com
# Date: 2023-28-03
# Description: This script creates 100  random  users, creates OUs, and coorelating groups. 

function Generate-FakeFileShare {
    param (
        [string]$RootPath = "C:\CorporateFileShare",
        [string]$ApiKey,
        [ValidateSet("gpt-4", "gpt-3.5-turbo", "gpt-4-1106-preview")]
        [string]$Model = "gpt-3.5-turbo",
        [ValidateRange(1, 4000)]
        [int]$MaxTokens = 4000,
        [switch]$Verbose,
        [switch]$Debug
    )

    # Check if API Key is provided
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Host "OpenAI API Key is required."
        return
    }

    $openAiApiKey = $ApiKey

    [net.servicepointmanager]::SecurityProtocol = [net.securityprotocoltype]::Tls12

    # Function to call OpenAI API Chat function

    Write-Host  "[!] Creating Fake File Share in $RootPath"
    function Invoke-OpenAI($prompt) {
        $uri = "https://api.openai.com/v1/chat/completions"
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "user"
                    content = $prompt
                }
            )
            temperature = 1
            max_tokens = $MaxTokens
            top_p = 1
            frequency_penalty = 0
            presence_penalty = 0
        } | ConvertTo-Json

        $headers = @{
            "Authorization" = "Bearer $openAiApiKey"
            "Content-Type" = "application/json"
        }

        try {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers
            if ($Verbose -eq $True){
                Write-Host "[#]Received response from OpenAI"
            }
            $responseText = $response.choices[0].message.content
            if ($Verbose -eq $True){
                Write-Host "[#]Response Text: $responseText"
            }
            return $responseText
        } catch {
            Write-Host "Error calling OpenAI API: $_"
        }
    }

    # Function to create different types of files with OpenAI generated content
    function Create-File($path, $department, $fileType, $fileNumber) {
        # Generate a dynamic part of the file name that isn't the dumbest file name you have possibly ever seen in your life
        $prompt = "Generate a realistic and unique file name for a $fileType file in the $department department. This is file number $fileNumber. The file number should not be included in the name. This could be a personal document for an employee in the department or a department wide document, randomize which one. The file name should not ever include the department name in the name"
        if($Debug -eq $true){
        Write-Host $prompt
        }
        $dynamicNamePart = Invoke-OpenAI $prompt
        
        # Honestly the GPT3.5 model is so f**king weird with what you tell it to do it will be like "thisIsAFile.docx".docx.docx....wtf?
        if ($Model -eq "gpt-3.5-turbo") {
            $dynamicNamePart = $dynamicNamePart.Replace('"', '').Trim()
            if ($dynamicNamePart.EndsWith($fileType)) {
                $fileName = $dynamicNamePart
            } else {
                $fileName = $dynamicNamePart + $fileType
            }
        } else {
            # Existing logic for non gpt-3.5-turbo models
            if ([string]::IsNullOrEmpty($dynamicNamePart)) {
                $dynamicNamePart = [System.IO.Path]::GetRandomFileName().Split('.')[0]
            } elseif ($dynamicNamePart.EndsWith($fileType)) {
                $fileName = $dynamicNamePart
            } else {
                $fileName = $dynamicNamePart.Trim() + $fileType
            }
        }

        write-host "[+]Creating File = $filename"

        $filePath = Join-Path -Path $path -ChildPath $fileName

        # Generate content for the file that is somewhat beleivable and doesn't always end with the "this is a simluated document and shouldn't be real envionrment"....we know
        $contentPrompt = "Write a realistic and department-specific document content for a $fileType file in the $department department with the file name being $dynamicNamePart. This content will be simulating a real envinoment so do not include a disclaimer about it being a simulated document. Your response should only include what is relevant to the document and should not include any descriptions about it"
        if($Debug -eq $true){
            Write-Host $ContentPrompt
            }
        $content = Invoke-OpenAI $contentPrompt

        # Handle different file types
        switch ($fileType) {
            #if people read comments just know this was the biggest hell hole to figure out how to do. Why are comm objects so stupid
            ".docx" {
                try {
                    $word = New-Object -ComObject Word.Application
                    # Set to $False because we hackers and we don't want to constatly see the window we are excuting
                    if ($Debug -eq $True){
                        $word.Visible = $True 
                    }else{
                        $word.Visible = $False
                    }
                    $document = $word.Documents.Add()
                    $document.Range().Text = $content
                    $wdFormatDocument = 16 # Word document format
            
                    # Cast $filePath to a string explicitly
                    $filePathString = [string]$filePath
            
                    # Use SaveAs2 for saving the document
                    $document.SaveAs2($filePathString, $wdFormatDocument)
                } catch {
                    Write-Host "Error: $_"
                    Write-Error "Word Failed to Save document: $filePathString)"
                } finally {
                    $document.Close()
                    $word.Quit()
                    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word)
                }
            }
            
            
            ".csv" {
                # Convert the content to a CSV format and save as XLSX cause honestly i coudlnt' be bothered to do what i did with word again
                $contentLines = $content -split '\r?\n' # Splitting the content into lines

                # Generating the CSV content
                $csvContent = $contentLines | ForEach-Object {
                    if (-not [string]::IsNullOrWhiteSpace($_)) {
                        # This ensures we only process non-empty lines
                        $line = $_ -replace ' ', '' # Remove spaces if needed, or adjust as necessary
                        $line
                    }
                } | Out-String -Width 4096 # Convert the array back to a single string
                
                # Exporting the data to a CSV file
                $csvContent | Out-File -FilePath $filePath -Encoding UTF8
            }
            ".txt"  {
                $content | Out-File -FilePath $filePath -Encoding utf8
            }
            default {
                $content | Out-File -FilePath $filePath -Encoding utf8
            }
        }
    }
    
    # Creating the directory structure and files
    $departments = @("HR", "Finance", "IT", "Marketing")
    $fileTypes = @(".docx", ".csv", ".txt")


    foreach ($dept in $departments) {
        $deptPath = Join-Path -Path $RootPath -ChildPath $dept
        New-Item -ItemType Directory -Force -Path $deptPath
    
        1..50 | ForEach-Object {
            # Select a random file type
            $randomType = Get-Random -InputObject $fileTypes
    
            # Call the Create-File function with the randomly selected file type
            Create-File $deptPath $dept $randomType $_ $Model
        }
    }

    Write-Host "File generation completed at $RootPath"
}

