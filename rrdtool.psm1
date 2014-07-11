<#
    .AUTHOR Nicolas BELOT

    .SYNOPSIS
        Manage rrd file 

    .DESCRIPTION
    

#>        
# RRDTOOL Module
# DS {
#    NAme :
#    Type :
#    Heartbeat :
#    Min :
#    Max :
#}

$rrdexe = (get-childitem -Path c:\  -Filter rrdtool.exe -Recurse -ErrorAction SilentlyContinue)[0].FullName

function New-RRD {
param ($filename, $step, $DS, $RRA)
    $sDs = @($DS |% { "DS:$($_.Name):$($_.Type):$($_.hearbeat):$($_.min):$($_.Max) " }  )
    $sRRA = @( $RRA |% { "RRA:$($_.Type):$($_.XFF):$($_.minPDP):$($_.nb) " })
    Write-Host "$rrdexe create $filename -s $step $sDs $sRRA"
    $param =  @( 'create', $filename, '-s', $step) + $sDs+ $sRRA
    write-host $param
    & $rrdexe $param
    return new-object -type psobject  -property @{File=$filename }

}

function New-DataSource {
    param( $dsname, $type="GAUGE", $hb=600, $min="0", $max="U")
    return new-object -type psobject  -property @{Name=$dsname;Type=$type;Hearbeat=$hb;Min=$min;Max=$max}
}

function New-RRA {
    param( $type,$XFF=0.5,$minPDP=1,$nb=2048)
    return new-object -type psobject  -property @{Type=$type.ToUpper();Xff=$xff;minPDP=$MinPDP;nb=$Nb}
}

function Get-RRdSource {
    param( $filename )
    return new-object -type psobject  -property @{File=$filename }
}

function Get-DataSource {
    param( $rrdobject)
    & $rrdexe info $($rrdobject.file)
}

function Get-Graph {
    param( $rrd, $format, $file )
    "$rrdexe graph $file -a $format --title `"test`" DEF:chrome=$($rrd.file):Process:AVERAGE LINE1:chrome#FF0000:Chrome"
    & $rrdexe graph $file -a $format --title "test" DEF:chrome=$($rrd.file):Process:AVERAGE LINE1:chrome#FF0000:Chrome
}

function Update-RRD {
    param( $rrd , $values )
    $svalue = "N:$($values -join ':')"
    "$rrdexe updatev $($rrd.file) $svalue"
    $param = @('updatev', $($rrd.file), $svalue)
    $param
    & $rrdexe $param
}
