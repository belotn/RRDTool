RRDTool
=======

RRDTool Module for Powershell

Online Help : http://get-xablog.fr/?p=605

TODO
	Create Enumaration for limited option set (graph entry, DS type etc)
	More usable powershell object return
	Pipelinable parameters
v1.0.6
    Add function to Add a Datasource in an exsiting RRD file
v1.0.5
    Add function CDEF
    Add graphitems type AREA
            and stackable line and Aera
v1.0.4
    Get-GRaph now accept Start and End time parameters
v1.0.3
    Autoprotect ":" in Grpint Format
    MIN, MAX, AVG in VDEF are automatically transform in real CF name
    get-graphdef did not try to rewrite RRD.DS field

v1.0.2
    Get-RrdSource et Get-DataSource return  an object with DSs and RRAs
    
v1.0.1
	Add Manifest Information
	Add InLine Module Help
	Can generate a graph 
		- But we still have CMD /C command line length restriction

v0.0
	Can create RRD and update them. 

		
	
