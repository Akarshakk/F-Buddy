# Comprehensive UI Theme Consistency Script for Finzo
# This script updates all Dart files to use theme-aware colors

$libPath = "lib"

# Define color replacements - only replace obvious hardcoded UI colors
# Preserve Colors.transparent, Colors.amber (specific use cases)
$replacements = @{
    'Colors\.black87' = 'ColorHelper.getTextPrimaryColor(context)'
    'Colors\.black54' = 'ColorHelper.getTextSecondaryColor(context)'
    'Colors\.black45' = 'ColorHelper.getTextSecondaryColor(context).withOpacity(0.7)'
    'Colors\.black38' = 'ColorHelper.getTextSecondaryColor(context).withOpacity(0.6)'
    'Colors\.black26' = 'ColorHelper.getBorderColor(context)'
    'Colors\.black12' = 'ColorHelper.getBorderColor(context).withOpacity(0.5)'
    'Colors\.black' = 'ColorHelper.getTextPrimaryColor(context)'
    'Colors\.white70' = 'ColorHelper.getTextLightColor(context).withOpacity(0.7)'
    'Colors\.white60' = 'ColorHelper.getTextLightColor(context).withOpacity(0.6)'
    'Colors\.white54' = 'ColorHelper.getTextLightColor(context).withOpacity(0.54)'
    'Colors\.white38' = 'ColorHelper.getTextLightColor(context).withOpacity(0.38)'
    'Colors\.white24' = 'ColorHelper.getTextLightColor(context).withOpacity(0.24)'
    'Colors\.white12' = 'ColorHelper.getTextLightColor(context).withOpacity(0.12)'
    'Colors\.white10' = 'ColorHelper.getTextLightColor(context).withOpacity(0.1)'
    'Colors\.grey\[900\]' = 'ColorHelper.getTextPrimaryColor(context)'
    'Colors\.grey\[800\]' = 'ColorHelper.getTextPrimaryColor(context)'
    'Colors\.grey\[700\]' = 'ColorHelper.getTextSecondaryColor(context)'
    'Colors\.grey\[600\]' = 'ColorHelper.getTextSecondaryColor(context)'
    'Colors\.grey\[500\]' = 'ColorHelper.getTextSecondaryColor(context)'
    'Colors\.grey\[400\]' = 'ColorHelper.getBorderColor(context)'
    'Colors\.grey\[300\]' = 'ColorHelper.getBorderColor(context)'
    'Colors\.grey\[200\]' = 'ColorHelper.getBorderColor(context)'
    'Colors\.grey\[100\]' = 'ColorHelper.getSurfaceColor(context)'
    'Colors\.grey\[50\]' = 'ColorHelper.getBackgroundColor(context)'
}

# Get all Dart files
$dartFiles = Get-ChildItem -Path $libPath -Filter "*.dart" -Recurse

$filesModified = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $modified = $false
    
    # Apply each replacement
    foreach ($pattern in $replacements.Keys) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacements[$pattern]
            $modified = $true
        }
    }
    
    # Only write if content changed
    if ($modified -and $content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $filesModified++
        Write-Host "Updated: $($file.FullName)"
    }
}

Write-Host "`nTotal files modified: $filesModified"
