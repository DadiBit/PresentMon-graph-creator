param (
	[string]$InFile=$(if(!$(Read-Host -Prompt 'Csv file name')){'graph.csv'}),
	[string]$OutFile="graph.png",
	[string]$Title=$(Read-Host -Prompt 'Title name')
)
if (!$(split-path $OutFile -IsAbsolute)) {
	$OutFile=$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$OutFile"))
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

[xml]$ConfigFile=Get-Content "PresentMon-graph-creator-configuration.xml"
$ImageBackground=$ConfigFile.configuration.AdvancedSettings.brush.ImageBackground.split(',')|%{iex $_}
$GridlineBackground=$ConfigFile.configuration.AdvancedSettings.brush.GridlineBackground.split(',')|%{iex $_}
$ColumnBackground=$ConfigFile.configuration.AdvancedSettings.brush.BarBackground.split(',')|%{iex $_}

$csv=import-csv $InFile
$raw=0
$tot=0
$min=0
$max=0
$csv | foreach-object {
	$tot+=[double]$_.MsUntilDisplayed
	if ([double]$_.MsUntilDisplayed -gt $max) {$max=[double]$_.MsUntilDisplayed}
	if ($min -eq 0) {$min=$max}
	if ([double]$_.MsUntilDisplayed -lt $min) {$min=[double]$_.MsUntilDisplayed}
	$raw++
}
if ($Title) {
	$bmp=new-object System.Drawing.Bitmap 1000,350
} else {
	$bmp=new-object System.Drawing.Bitmap 1000,250
}
$brushBg=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb($ImageBackground[0],$ImageBackground[1],$ImageBackground[2],$ImageBackground[3]))
$brushGl=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb($GridlineBackground[0],$GridlineBackground[1],$GridlineBackground[2],$GridlineBackground[3]))
$brushGp=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb($ColumnBackground[0],$ColumnBackground[1],$ColumnBackground[2],$ColumnBackground[3]))
$brushTx=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb(255,0,0,0))
$fontTx=new-object System.Drawing.Font Arial,25
$graphics=[System.Drawing.Graphics]::FromImage($bmp)
$graphics.FillRectangle($brushBg,0,0,$bmp.Width,$bmp.Height)
if ($Title) {
	$brushTl=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb(255,0,0,0))
	$fontTl=new-object System.Drawing.Font Arial,25
	$graphics.FillRectangle($brushGp,250,0,500,50)
	$graphics.FillEllipse($brushGp,225,0,50,50)
	$graphics.FillEllipse($brushGp,725,0,50,50)
	$graphics.DrawString($Title,$fontTl,$brushTl,250+250-(([System.Windows.Forms.TextRenderer]::MeasureText($Title,$fontTl)).width/2),0+25-(([System.Windows.Forms.TextRenderer]::MeasureText($Title,$fontTl)).height/2))
	$offset+=100
}
$graphics.FillRectangle($brushGl,172,$offset+10,3,230)
$graphics.FillRectangle($brushGp,175,$offset+25,($bmp.Width-300)/$max*($tot/$raw),50)
$graphics.DrawString('Avarage: ',$fontTx,$brushTx,10,$offset+25+25-(([System.Windows.Forms.TextRenderer]::MeasureText($tot/$raw,$fontTx)).height/2))
$graphics.DrawString([math]::Round(($tot/$raw),1),$fontTx,$brushTx,175+(($bmp.Width-300)/$max*($tot/$raw)),$offset+25+25-(([System.Windows.Forms.TextRenderer]::MeasureText($tot/$raw,$fontTx)).height/2))
$graphics.FillRectangle($brushGp,175,$offset+100,($bmp.Width-300)/$max*$max,50)
$graphics.DrawString('Maximum: ',$fontTx,$brushTx,10,$offset+100+25-(([System.Windows.Forms.TextRenderer]::MeasureText($max,$fontTx)).height/2))
$graphics.DrawString([math]::Round($max,1),$fontTx,$brushTx,175+(($bmp.Width-300)/$max*$max),$offset+100+25-(([System.Windows.Forms.TextRenderer]::MeasureText($max,$fontTx)).height/2))
$graphics.FillRectangle($brushGp,175,$offset+175,($bmp.Width-300)/$max*$min,50)
$graphics.DrawString('Minimum: ',$fontTx,$brushTx,10,$offset+175+25-(([System.Windows.Forms.TextRenderer]::MeasureText($min,$fontTx)).height/2))
$graphics.DrawString([math]::Round($min,1),$fontTx,$brushTx,175+(($bmp.Width-300)/$max*$min),$offset+175+25-(([System.Windows.Forms.TextRenderer]::MeasureText($min,$fontTx)).height/2))
$graphics.Dispose()
$bmp.Save($OutFile)
Invoke-Item $OutFile
echo "$($bar)"
echo "Avarage: $($tot/$raw)"
echo "Maximum: $($max)"
echo "Minimum: $($min)"
pause