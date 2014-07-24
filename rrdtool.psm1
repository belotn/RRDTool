<#
    .AUTHOR Nicolas BELOT

    .SYNOPSIS
        Manage rrd file 

    .DESCRIPTION
    

#>
#TODO : Add enumaration for CG function and Grph line
#       Pipelinable parameters

$rrdexe = (get-childitem -Path c:\  -Filter rrdtool.exe -Recurse -ErrorAction SilentlyContinue)[0].FullName
if( -not($rrdexe)){
   throw [System.IO.FileNotFoundException] "No RRDTool found on this computer"
}
$rrdversion = & $rrdexe |% { if( $_ -match "RRDtool\s(\d\.\d\.\d)"){ $matches[1] } }

function Get-RRDToolInfo {
<#
    .SYNOPSIS
        Return information about the rrdtool found on the computer

#>
    return New-Object -TypeName PSObject -property @{"FileName" = $rrdexe ; "Version" = $rrdversion }
}


function New-RRD {
<#
    .SYNOPSIS
        Create a new Round Roubin Database 

    .DESCRIPTION
        Create A new RRD File with the required DS and RRA

    .PARAMETER filename
        Mandatory - the name of the rrd file

    .PARAMETER step
        Base Interval of data injection

    .PARAMETER DS
        An array containing the DataSource stored in the RRD file, you can create DS with New-DataSource

    .PARAMETER RRA
        An Array containing the defined Round Robin Archive in the RRD file, you can create RRA with New-RRA

    .LINK
        http://oss.oetiker.ch/rrdtool/doc/rrdcreate.en.html

#>
param ([Parameter(Mandatory=$true)][string]$filename,[int]$step, [object[]]$DS, [object[]]$RRA)
    $sDs = @($DS |% { "DS:$($_.Name):$($_.Type):$($_.hearbeat):$($_.min):$($_.Max) " }  )
    $sRRA = @( $RRA |% { "RRA:$($_.Type):$($_.XFF):$($_.minPDP):$($_.nb) " })
    Write-Host "$rrdexe create $filename -s $step $sDs $sRRA"
    $param =  @( 'create', $filename, '-s', $step) + $sDs+ $sRRA
    & $rrdexe $param
    return new-object -type psobject  -property @{'File'=$filename; 'RRA'= $RRA; 'DS' = $DS }

}

function New-DataSource {
<#
    .SYNOPSIS
        Return a string representing a new datasource definition for the RRD creation

    .DESCRIPTION
        Return a string representing a new datasource definition for the RRD creation

    .PARAMETER dsname
        Mandatory - the datasource nanme

    .PARAMETER heartbeat
        interval between measures, default 600 

    .PARAMETER Min
        The minimum value of the datasource, default 0

    .PARAMETER Max
        The minimum value of the datasource, default U.

    .NOTE
        Depending of your RRD version, the Max parameter must be set to anything that U to work properly.

    .LINK
        http://oss.oetiker.ch/rrdtool/doc/rrdcreate.en.html

#>
    param( [Parameter(Mandatory=$true)][string]$dsname, [string]$type="GAUGE", [int]$hb=600, [string]$min="0", [string]$max="U")
    return new-object -type psobject  -property @{Name=$dsname;Type=$type;Hearbeat=$hb;Min=$min;Max=$max}
}

function New-RRA {
<#
    .SYNOPSIS
        Return a string representing a new RRA definition for the RRD creation

    .DESCRIPTION
        Return a string representing a new RRA definition for the RRD creation

    .PARAMETER type
        Mandatory - the type of the RRA - MIN, MAX, AvERAGE

    .PARAMETER XFF
        XFF, default to 0.5

    .PARAMETER MinPDP
        The minimum value store, default 1

    .PARAMETER NB
        the number of record, default 2048.

    .LINK
        http://oss.oetiker.ch/rrdtool/doc/rrdcreate.en.html

#>
    param( $type,$XFF=0.5,$minPDP=1,$nb=2048)
    return new-object -type psobject  -property @{Type=$type.ToUpper();Xff=$xff;minPDP=$MinPDP;nb=$Nb}
}

function Get-RRdSource {
<#
    .SYNOPSIS
        Return an object usable with get-graph function

    .DESCRIPTION
        Return an object usable with get-graph function
#>
    param( $filename )
    return  Get-DataSource( new-object -type psobject  -property @{File=$filename } )
}

function Get-DataSource {
<#
    .SYNOPSIS
        Return information about the datasource in the given RRD File

    .DESCRIPTION
        Return information about the datasource in the given RRD File

    .NOTE
        This funciton will change to return a usable object
#>
    param( $rrdobject)
    $content =  & $rrdexe info $($rrdobject.file)
    $rra = @()
    $ds = @()
    $content |% {
	    if($_ -match '(ds|rra)\[([^\]]*)\]\.([^=]*)\s=\s(.*)'){
		    if($matches[1] -eq 'ds'){
			    if($matches[3] -eq 'index'){
				    $ds+= (new-object PSObject -property @{'Name'=$matches[2]})
				    $index = $matches[4]
			    }else{
				    $ds[$index]= $ds[$index] | add-member -type Noteproperty -Name $matches[3] -value $matches[4] -passthru
				    try{
					    $ds[$index]."$($matches[3])" = [float]::Parse($matches[4])
				    }Catch{
			
				    }
			    }
		    }elseif($matches[1] -eq 'rra'){
			    if($matches[2] -ne $index -or $rra.Count -eq 0){
				    $rra+= (new-object PSObject -property @{'CF'=$matches[4]})
				    $index = $matches[2]
			    }elseif( [string]::Concat($matches[3],'=',$matches[4]) -match 'cdp_prep\[(\d*)\]\.([^=]*)=(.*)'){
    				if(-not($rra[$index].cdp_prep)){
	    				$rra[$index] = $rra[$index] | add-member -type noteproperty -name cdp_prep -value @() -passthru
		    		}
				    if( -not($rra[$index].cdp_prep[$matches[1]]) ){
					    $rra[$index].cdp_prep+=(new-object PSOBject -property @{ $matches[2] =$matches[3] } )
				    }else{
					    $rra[$index].cdp_prep[$matches[1]] = $rra[$index].cdp_prep[$matches[1]] | add-member -type noteproperty -name $matches[2] -value $matches[3] -passthru
				    }
			    }else{
				    $rra[$index] = $rra[$index] | add-member -type Noteproperty -Name $matches[3] -value $matches[4] -passthru
				    try {
					    $rra[$index].$($matches[3]) = [float]::Parse($matches[4])
				    }catch{
				
				    }
			    }
		    }
	    } 
    }
    return $rrdobject | add-member -type NoteProperty -name DS -value $ds -passthru | add-member -type noteproperty -name RRA -value $rra -passthru
}

function Get-Graph {
<#
    .SYNOPSIS
        Create a new RRD Graph

    .DESCRIPTION
        Create a new RRD graph 

    .PARAMETER format
        The format of the generated graph

    .PARAMETER file
        Filename of the graph

    .PARAMETER title
        Title of the graph
        
    .PARAMETER def
        An array of  DEF, Datas fetched from the RRD graph

    .PARAMETER vdef
        An array of VDEF, Values and/or a time according to the RPN statements used

    .PARAMETER line
        List of displayed item in the graph
    
    .PARAMETER start
        Start grah timestamp

    .PARAMETER end
        End graph timestamp
            
    .LINKS
        http://oss.oetiker.ch/rrdtool/doc/rrdgraph_data.en.html
        http://oss.oetiker.ch/rrdtool/doc/rrdgraph_examples.en.html
        http://oss.oetiker.PNGch/rrdtool/doc/rrdgraph.en.html
#>
    param( $format, $file, $title,$start,$end,  $def,$vdef, $line  )
    $param = @('graph', $file, '-a', $format, '--title', "`"$title`"") 
    if($start) {
        $param += @('-s', $start  )
        if($end){
            $param += @( '-e', $end)
        }
    }
    $param += $def + $vdef +$line
    "$rrdexe" + ' ' + $param -join " "
#    & $rrdexe $param 
    $cmdline = $rrdexe + ' ' + $param -join " "
    $cmline.length
    CMD /C $cmdline
}

function NEw-GraphDEF {
<#
    .SYNOPSIS
        Return a string representing a graph DEF

    .DESCRIPTION
        Return a string representing a graph DEF, usable with GET-GRAPH.

    .PARAMETER rrd
        An rrd object

    .PARAMETER mesure
        The Datasource to a graph

    .PARAMETER cf
        The consilidation function to used

    .PARAMETER name
        the vname of the DEF

    .LINKS
        http://oss.oetiker.ch/rrdtool/doc/rrdgraph_data.en.html
#>
    param($rrd, $mesure, $cf, $name)
    if( ($rrd.DS |% { $_.NAme}) -contains $mesure){
        return "DEF:$($name)=$($rrd.file):$($mesure):$($cf.toUpper())"
    }
}

function New-graphLine {
<#
    .SYNOPSIS
        Return a string representing a graph displayed item

    .DESCRIPTION
        Return a string representing a graph displayed item, usable with GET-GRAPH.

    .PARAMETER type
        the type of the item

    .PARAMETER mesure
        the vname to be displayed

    .PARAMETER color
        color, not usable with all type

    .PARAMETER desc
        legend of the item, not usable with all type

    .PARAMETER format
        Format of the item, not usable with all type 

    .PARAMETER padding
        Right Padding of comment string, not usable with all type 

    .PARAMTER nl
        Add new-line after the comment

    .LINKS
        http://oss.oetiker.ch/rrdtool/doc/rrdgraph_data.en.html
#>
    param($type, $mesure,$color,$desc,$Format,$comment,$padding,[switch]$nl)
    $ret =''
    if($type -like 'LINE?'){
        $ret = "$($type):$($mesure)$($color):`"$($desc)`""
    }elseif($type -eq 'GPRINT'){
        $ret = "$($type):$($mesure):`"$($format.replace(':','\:'))`""
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
<#
    .SYNOPSIS
        Return a string representing a graph VDEF

    .DESCRIPTION
        Return a string representing a graph VDEF, usable with GET-GRAPH.

    .PARAMETER name
        Name of the VDEF

    .PARAMETER vname
        defined vanme

    .PARAMETER CF
        Consolidation function
#>
   param($name, $vname,$CF)
   if($CF -eq 'MIN'){
    $cf = 'MINIMUM'
   }
   if($CF -eq 'MAX'){
    $cf = 'MAXIMUM'
   }
   if($CF -eq 'AVG'){
    $cf = 'AVERAGE'
   }

   return "VDEF:$($name)=$($vname),$($cf.toUpper())"
}


function Update-RRD {
<#
    .SYNOPSIS
        Update RRD Date

    .DESCRIPTION
        Insert Data in the RRD File

    .PARAMETER rrd
        Object representing the rrd file

    .PARAMETER values
        Array of recorded values 

    .PARAMETER timestamp
          When the values were recorded, default to N (now)
#>
    param( $rrd , $values, $timestamp='N' )
    $svalue = "$($timestamp):$($values -join ':')"
    "$rrdexe updatev $($rrd.file) $svalue"
    $param = @('updatev', $($rrd.file), $svalue)
    $param
    & $rrdexe $param
}
