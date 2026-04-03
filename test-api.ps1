param(
    [string]$BaseUrl = "http://localhost:5000"
)

$ErrorActionPreference = "Stop"
$script:FailureCount = 0
$script:CreatedTaskId = $null

function Write-Pass {
    param([string]$Message)
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    $script:FailureCount++
}

function Invoke-ApiRequest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Method,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Body = ""
    )

    $url = "$BaseUrl$Path"

    try {
        if ($Body) {
            $response = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $url -ContentType "application/json" -Body $Body
        } else {
            $response = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $url
        }

        return [PSCustomObject]@{
            StatusCode = [int]$response.StatusCode
            Body = $response.Content
        }
    }
    catch {
        if ($null -eq $_.Exception.Response) {
            throw
        }

        $resp = $_.Exception.Response
        $errorBody = ""
        $statusCode = 0

        # PowerShell 7 (Linux/macOS runner): HttpResponseMessage
        if ($resp.GetType().FullName -eq "System.Net.Http.HttpResponseMessage") {
            $statusCode = [int]$resp.StatusCode
            if ($null -ne $resp.Content) {
                $errorBody = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            }
        }
        # Windows PowerShell: HttpWebResponse with GetResponseStream()
        elseif ($resp.PSObject.Methods.Name -contains "GetResponseStream") {
            $statusCode = [int]$resp.StatusCode
            $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $errorBody = $reader.ReadToEnd()
        }
        else {
            $statusCode = [int]$resp.StatusCode
            if ($null -ne $resp.Content) {
                $errorBody = [string]$resp.Content
            }
        }

        return [PSCustomObject]@{
            StatusCode = $statusCode
            Body = $errorBody
        }
    }
}

function Convert-JsonSafe {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    try {
        return ($Text | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}

Write-Host "[INFO] Base URL: $BaseUrl" -ForegroundColor Cyan

# 1) Healthcheck
$health = Invoke-ApiRequest -Method "GET" -Path "/health"
$healthJson = Convert-JsonSafe -Text $health.Body
if ($health.StatusCode -eq 200 -and $healthJson.status -eq "ok") {
    Write-Pass "GET /health retourne 200 et status=ok"
} else {
    Write-Fail "GET /health inattendu (status=$($health.StatusCode), body=$($health.Body))"
}

# 2) Liste initiale
$list1 = Invoke-ApiRequest -Method "GET" -Path "/tasks"
$list1BodyTrimmed = $list1.Body.Trim()
if ($list1.StatusCode -eq 200 -and $list1BodyTrimmed.StartsWith("[") -and $list1BodyTrimmed.EndsWith("]")) {
    Write-Pass "GET /tasks retourne 200 et un tableau"
} else {
    Write-Fail "GET /tasks inattendu (status=$($list1.StatusCode), body=$($list1.Body))"
}

# 3) Creation
$uniqueTitle = "Test portfolio $(Get-Date -Format yyyyMMddHHmmss)"
$createPayload = @{ title = $uniqueTitle } | ConvertTo-Json
$create = Invoke-ApiRequest -Method "POST" -Path "/tasks" -Body $createPayload
$createJson = Convert-JsonSafe -Text $create.Body
if ($create.StatusCode -eq 201 -and $createJson.id -and $createJson.title -eq $uniqueTitle) {
    $script:CreatedTaskId = [int]$createJson.id
    Write-Pass "POST /tasks cree une tache (id=$script:CreatedTaskId)"
} else {
    Write-Fail "POST /tasks inattendu (status=$($create.StatusCode), body=$($create.Body))"
}

# 4) Verification presence
$list2 = Invoke-ApiRequest -Method "GET" -Path "/tasks"
$list2JsonRaw = Convert-JsonSafe -Text $list2.Body
$list2Items = @()
if ($null -ne $list2JsonRaw) {
    $list2Items = @($list2JsonRaw)
}
$found = $false
if ($script:CreatedTaskId) {
    $found = $null -ne ($list2Items | Where-Object { $_.id -eq $script:CreatedTaskId })
}
if ($list2.StatusCode -eq 200 -and $found) {
    Write-Pass "GET /tasks contient la tache creee"
} else {
    Write-Fail "La tache creee est introuvable (status=$($list2.StatusCode), body=$($list2.Body))"
}

# 5) Suppression tache creee
if ($script:CreatedTaskId) {
    $deleteOk = Invoke-ApiRequest -Method "DELETE" -Path "/tasks/$script:CreatedTaskId"
    if ($deleteOk.StatusCode -eq 200) {
        Write-Pass "DELETE /tasks/<id> supprime la tache"
    } else {
        Write-Fail "DELETE /tasks/$script:CreatedTaskId inattendu (status=$($deleteOk.StatusCode), body=$($deleteOk.Body))"
    }
} else {
    Write-Fail "Suppression ignoree: aucune tache creee"
}

# 6) Suppression inexistante
$deleteMissing = Invoke-ApiRequest -Method "DELETE" -Path "/tasks/999999"
if ($deleteMissing.StatusCode -eq 404) {
    Write-Pass "DELETE /tasks/999999 retourne 404"
} else {
    Write-Fail "DELETE /tasks/999999 inattendu (status=$($deleteMissing.StatusCode), body=$($deleteMissing.Body))"
}

# 7) Validation titre vide
$invalidPayload = @{ title = "   " } | ConvertTo-Json
$invalid = Invoke-ApiRequest -Method "POST" -Path "/tasks" -Body $invalidPayload
if ($invalid.StatusCode -eq 400) {
    Write-Pass "POST /tasks avec titre vide retourne 400"
} else {
    Write-Fail "POST /tasks invalide inattendu (status=$($invalid.StatusCode), body=$($invalid.Body))"
}

if ($script:FailureCount -gt 0) {
    Write-Host "[RESULT] $script:FailureCount test(s) en echec" -ForegroundColor Red
    exit 1
}

Write-Host "[RESULT] Tous les tests sont passes" -ForegroundColor Green
exit 0
