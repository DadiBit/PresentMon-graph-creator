param (
	[string]$InFile=$(Read-Host -Prompt 'Csv file name'),
	[string]$OutFile,
	[string]$Title=$(Read-Host -Prompt 'Title name')
)

$ConfigFile=Import-LocalizedData -FileName PresentMon-graph-creator.psd1
if (!$InFile) {$InFile=$ConfigFile.basic.InFile}
if (!$OutFile) {$OutFile=$ConfigFile.basic.OutFile}
if (!$(split-path $OutFile -IsAbsolute)) {$OutFile=$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$OutFile"))}

$ImageBackground=$ConfigFile.advanced.ImageBackground.split(',')|%{iex $_}
$GridlineBackground=$ConfigFile.advanced.GridlineBackground.split(',')|%{iex $_}
$BarBackground=$ConfigFile.advanced.BarBackground.split(',')|%{iex $_}
$LabelText=$ConfigFile.advanced.LabelText.split(',')|%{iex $_}
$TitleText=$ConfigFile.advanced.TitleText.split(',')|%{iex $_}
$TitleBackground=$ConfigFile.advanced.TitleBackground.split(',')|%{iex $_}
$TitleType=$ConfigFile.advanced.TitleType

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

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
$brushBb=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb($BarBackground[0],$BarBackground[1],$BarBackground[2],$BarBackground[3]))
$brushTx=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb($LabelText[0],$LabelText[1],$LabelText[2],$LabelText[3]))
$fontTx=new-object System.Drawing.Font Arial,25
$graphics=[System.Drawing.Graphics]::FromImage($bmp)
$graphics.FillRectangle($brushBg,0,0,$bmp.Width,$bmp.Height)
if ($Title) {
	$brushTl=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb($TitleText[0],$TitleText[1],$TitleText[2],$TitleText[3]))
	$brushTb=[System.Drawing.SolidBrush]::New([System.Drawing.Color]::FromArgb($TitleBackground[0],$TitleBackground[1],$TitleBackground[2],$TitleBackground[3]))
	$fontTl=new-object System.Drawing.Font Arial,25
	if ($TitleType -eq 0) {
		$graphics.FillRectangle($brushTb,250,0,500,50)
		$graphics.FillEllipse($brushTb,225,0,50,50)
		$graphics.FillEllipse($brushTb,725,0,50,50)
	} elseif ($TitleType -eq 1) {
		$graphics.FillRectangle($brushTb,250,0,500,50)
	} elseif ($TitleType -eq 2) {
		$graphics.FillRectangle($brushTb,250,0,500,50)
		$graphics.FillEllipse($brushTb,225,0,50,50)
		$graphics.FillEllipse($brushTb,725,0,50,50)
		$graphics.FillRectangle($brushTb,225,0,25,25)
		$graphics.FillRectangle($brushTb,750,0,25,25)
	} elseif ($TitleType -eq 3) {
		$graphics.FillRectangle($brushTb,250,0,500,50)
		$graphics.FillEllipse($brushTb,225,0,50,50)
		$graphics.FillEllipse($brushTb,725,0,50,50)
		$graphics.FillRectangle($brushTb,225,0,25,25)
		$graphics.FillRectangle($brushTb,750,25,25,25)
	} elseif ($TitleType -eq 4) {
		$graphics.FillRectangle($brushTb,250,0,500,25)
		$graphics.FillEllipse($brushTb,250,0,500,50)
	} elseif ($TitleType -eq 5) {
		$graphics.FillRectangle($brushTb,300,0,400,25)
		$graphics.FillEllipse($brushTb,250,0,100,50)
		$graphics.FillEllipse($brushTb,650,0,100,50)
		$graphics.FillRectangle($brushTb,300,0,400,50)
	} elseif ($TitleType -eq 6) {
		$graphics.FillRectangle($brushTb,250,0,500,25)
		$graphics.FillEllipse($brushTb,250,0,100,50)
		$graphics.FillEllipse($brushTb,650,0,100,50)
		$graphics.FillRectangle($brushTb,300,0,400,50)
	}
	$graphics.DrawString($Title,$fontTl,$brushTl,250+250-(([System.Windows.Forms.TextRenderer]::MeasureText($Title,$fontTl)).width/2),0+25-(([System.Windows.Forms.TextRenderer]::MeasureText($Title,$fontTl)).height/2))
	$offset+=100
}
$graphics.FillRectangle($brushGl,172,$offset+10,3,230)
$graphics.FillRectangle($brushBb,175,$offset+25,($bmp.Width-300)/$max*($tot/$raw),50)
$graphics.DrawString('Avarage: ',$fontTx,$brushTx,10,$offset+25+25-(([System.Windows.Forms.TextRenderer]::MeasureText($tot/$raw,$fontTx)).height/2))
$graphics.DrawString([math]::Round(($tot/$raw),1),$fontTx,$brushTx,175+(($bmp.Width-300)/$max*($tot/$raw)),$offset+25+25-(([System.Windows.Forms.TextRenderer]::MeasureText($tot/$raw,$fontTx)).height/2))
$graphics.FillRectangle($brushBb,175,$offset+100,($bmp.Width-300)/$max*$max,50)
$graphics.DrawString('Maximum: ',$fontTx,$brushTx,10,$offset+100+25-(([System.Windows.Forms.TextRenderer]::MeasureText($max,$fontTx)).height/2))
$graphics.DrawString([math]::Round($max,1),$fontTx,$brushTx,175+(($bmp.Width-300)/$max*$max),$offset+100+25-(([System.Windows.Forms.TextRenderer]::MeasureText($max,$fontTx)).height/2))
$graphics.FillRectangle($brushBb,175,$offset+175,($bmp.Width-300)/$max*$min,50)
$graphics.DrawString('Minimum: ',$fontTx,$brushTx,10,$offset+175+25-(([System.Windows.Forms.TextRenderer]::MeasureText($min,$fontTx)).height/2))
$graphics.DrawString([math]::Round($min,1),$fontTx,$brushTx,175+(($bmp.Width-300)/$max*$min),$offset+175+25-(([System.Windows.Forms.TextRenderer]::MeasureText($min,$fontTx)).height/2))
$graphics.Dispose()
$bmp.Save("$OutFile")
echo "Avarage: $($tot/$raw)"
echo "Maximum: $($max)"
echo "Minimum: $($min)"
pause