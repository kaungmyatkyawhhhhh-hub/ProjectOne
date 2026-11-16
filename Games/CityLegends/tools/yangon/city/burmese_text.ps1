# burmese_text.ps1 -In list.json -Out dir [-Font "Myanmar Text"] [-Size 120] [-Bold]
# Renders each { "id", "text" } of list.json (UTF-8) as white text on a transparent PNG <Out>/<id>_raw.png with WPF
# (DirectWrite shaping: Myanmar reordering and stacking come out right; PIL without raqm can't do it).
# Called by burmese_text.py, which crops and scales the results.
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Font = "Myanmar Text",
    [double]$Size = 120,
    [switch]$Bold
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase

$items = [System.IO.File]::ReadAllText($In, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
New-Item -ItemType Directory -Force $Out | Out-Null

$weight = if ($Bold) { [System.Windows.FontWeights]::Bold } else { [System.Windows.FontWeights]::Normal }
$typeface = New-Object System.Windows.Media.Typeface (
    (New-Object System.Windows.Media.FontFamily $Font),
    [System.Windows.FontStyles]::Normal, $weight, [System.Windows.FontStretches]::Normal)
$culture = [System.Globalization.CultureInfo]::GetCultureInfo("my-MM")
$pad = [int]($Size * 0.5)

foreach ($it in $items) {
    $ft = New-Object System.Windows.Media.FormattedText (
        [string]$it.text, $culture, [System.Windows.FlowDirection]::LeftToRight, $typeface, $Size,
        [System.Windows.Media.Brushes]::White, 1.0)
    $w = [int][math]::Ceiling($ft.WidthIncludingTrailingWhitespace) + 2 * $pad
    $h = [int][math]::Ceiling($ft.Height) + 2 * $pad
    $dv = New-Object System.Windows.Media.DrawingVisual
    $dc = $dv.RenderOpen()
    $dc.DrawText($ft, (New-Object System.Windows.Point ($pad, $pad)))
    $dc.Close()
    $bmp = New-Object System.Windows.Media.Imaging.RenderTargetBitmap ($w, $h, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $bmp.Render($dv)
    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
    $path = Join-Path $Out ($it.id + "_raw.png")
    $fs = [System.IO.File]::Create($path)
    $enc.Save($fs)
    $fs.Close()
    # baseline (px from the top of the PNG) so the caller can line words up
    Write-Output ("{0}`t{1}`t{2}" -f $it.id, ($pad + $ft.Baseline), $h)
}
