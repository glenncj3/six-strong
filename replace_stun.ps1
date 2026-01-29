Get-ChildItem -Path "C:\Users\glenn\Dev\six-strong" -Recurse -Include *.gd,*.json,*.md,*.tscn,*.cfg -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match 'stun_value') {
        $newContent = $content -replace 'stun_value', 'freeze_value'
        Set-Content $_.FullName $newContent -NoNewline
        Write-Host "Updated: $($_.FullName)"
    }
}
