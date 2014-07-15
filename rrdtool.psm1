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

#TODO : Add enumaration for CG function and Grph line

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
    return & $rrdexe info $($rrdobject.file)
}

function Get-Graph {
    param( $format, $file, $title, $def,$vdef, $line  )
    $param = @('graph', $file, '-a', $format, '--title', "`"$title`"" ) + $def + $vdef +$line
    "$rrdexe" + $param -join ' '
#    & $rrdexe $param 
    $cmdline = $rrdexe + ' ' + $param -join ' '
    CMD /C $cmdline
}

function NEw-GraphDEF {
    param($rrd, $mesure, $cf, $name)
    $ds = Get-DataSource $rrd
    if( $ds -like "*$mesure*"){
        return "DEF:$($name)=$($rrd.file):$($mesure):$($cf.toUpper())"
    }
}

function New-graphLine {
    param($type, $mesure,$color,$desc,$Format,$comment,$padding,[switch]$nl)
    $ret =''
    if($type -like 'LINE?'){
        $ret = "$($type):$($mesure)$($color):`"$($desc)`""
    }elseif($type -eq 'GPRINT'){
        $ret = "$($type):$($mesure):`"$($format)`""
    }elseif($type -eq 'COMMENT'){
        write-host $nl
        $ret = "COMMENT:`"$($comment.padLeft($padding))" 
        if($nl){
            $ret += "\l"
        }
        $ret += "`""
    }
    return $ret
}

function New-GraphVDEF {
   param($name, $vname,$CF)
   return "VDEF:$($name)=$($vname),$($cf.toUpper())"
}


function Update-RRD {
    param( $rrd , $values )
    $svalue = "N:$($values -join ':')"
    "$rrdexe updatev $($rrd.file) $svalue"
    $param = @('updatev', $($rrd.file), $svalue)
    $param
    & $rrdexe $param
}
