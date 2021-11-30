$PBExportHeader$test.sra
$PBExportComments$Generated Application Object
forward
global type test from application
end type
global transaction sqlca
global dynamicdescriptionarea sqlda
global dynamicstagingarea sqlsa
global error error
global message message
end forward

global variables
n_trace gn_trace

end variables

global type test from application
string appname = "test"
string displayname = "tracelog test"
end type
global test test

on test.create
appname="test"
message=create message
sqlca=create transaction
sqlda=create dynamicdescriptionarea
sqlsa=create dynamicstagingarea
error=create error
end on

on test.destroy
destroy(sqlca)
destroy(sqlda)
destroy(sqlsa)
destroy(error)
destroy(message)
end on

event open;gn_trace=create n_trace

//add custom message to log
gn_trace.of_log( this, 'application open ~r~ncommandline='+commandline, gn_trace.msg_open )

//set the name of the trace window
gn_trace.of_settitle( getApplication().displayname )

gn_trace.of_log( this, 'custom information message "<spec symbols>"', gn_trace.msg_info )
gn_trace.of_log( this, 'custom debug message', gn_trace.msg_debug )

// Profile TUKRNG01
SQLCA.DBMS = "SYC Adaptive Server Enterprise"
SQLCA.Database = "opale2000"
SQLCA.LogPass = 'valerie'
SQLCA.ServerName = "TUKRNG01"
SQLCA.LogId = "sa"
SQLCA.AutoCommit = True
SQLCA.DBParm = "Release='11.5'"

connect;
if sqlca.sqlcode<>0 then
	messagebox(getapplication().displayname,sqlca.sqlerrtext)
else
	//set sql error/message handler
	gn_trace.of_dbHandlerSet( sqlca )
	
	//do wrong sql
	execute immediate 'ksjadljsa d fjlsfdkjhdfv ksdf vls';
	messagebox(getapplication().displayname,'just a messagebox after sql error~r~n you can see error in the log.')
	
	//check that PB also see an error
	if sqlca.sqlcode<>0 then
		messagebox(getapplication().displayname,sqlca.sqlerrtext)
	end if
	
	//check the print command
	execute immediate "print 'my message from server!!!'";
	messagebox(getapplication().displayname,'just a messagebox after sql print command~r~n you should see the print message in the log.')
	
	
	
	gn_trace.of_dbHandlerDel( sqlca )
	disconnect;
end if

MessageBox(getapplication().displayname,'now we will add 1000 messages to the tracelog...')
long i
for i=1 to 1000
	gn_trace.of_log( this, 'the message number #'+string(i), gn_trace.msg_debug )
next
MessageBox(getapplication().displayname,'now we will generate system error...')
signalerror(33,'the error message text')

MessageBox(getapplication().displayname,'the end. check the log...')

end event

event close;destroy gn_trace

end event

event systemerror;String msg,obj

obj=error.WindowMenu
if error.Object<>'' and error.Object<>error.WindowMenu then obj+='.'+error.Object
if error.ObjectEvent<>'' then 
	obj+='.'+error.ObjectEvent
	if error.line>0 then obj+=' ('+string(error.line)+')'
end if

msg ='System error '+string(error.number)+': '
msg+=error.text
if isvalid(gn_trace) then gn_trace.of_log( obj, msg, gn_trace.msg_syserr )
if messageBox(displayName,msg,StopSign!,RetryCancel!,2)=2 then HALT CLOSE

end event

