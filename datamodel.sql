drop table et_collectl_cpu;
drop table wt_collectl_cpu;
drop table uv_collectl_cpu;
drop table collectl_cpu;
drop table myadmin.mylogtablecpu;
release mload collectl_cpu; 

CREATE MULTISET TABLE MYTESTDB.collectl_cpu
     (
      hostname VARCHAR(60),
      date_cpu DATE ,
      time_cpu TIME,
      user_cpu BIGINT,
      nice BIGINT,
      sys BIGINT,
      wait_cpu BIGINT,
      irq BIGINT,
      soft BIGINT,
      steal BIGINT,
      ideal BIGINT,
      totl BIGINT,
      guest BIGINT,
      guestN BIGINT,
      intrpt_ps BIGINT,
      ctx_ps BIGINT,
      proc_ps BIGINT,
      procque BIGINT,
      procrun BIGINT,
      lavg1 DECIMAL(10,2),
      lavg5 DECIMAL(10,2),
      lavg15 DECIMAL(10,2),
      runtot BIGINT,
      blktot BIGINT)
PRIMARY INDEX ( date_cpu,time_cpu,hostname);

drop table et_collectl_net;
drop table wt_collectl_net;
drop table uv_collectl_net;
drop table collectl_net;
drop table myadmin.mylogtablenet;
release mload collectl_net; 

CREATE MULTISET TABLE mytestdb.collectl_net 
     (
      hostname VARCHAR(60) ,
      date_net DATE,
      time_net TIME,
      RxPktTot bigint,
      TxPktTot bigint,
      RxKBTot bigint,
	  TxKBTot bigint,
	  RxCmpTot bigint,
	  RxMltTot bigint,
	  TxCmpTot bigint,
	  RxErrsTot bigint,
	  TxErrsTot bigint)
PRIMARY INDEX ( date_net,time_net,hostname );

drop table et_collectl_mem;
drop table wt_collectl_mem;
drop table uv_collectl_mem;
drop table collectl_mem;
drop table myadmin.mylogtablemem;
release mload collectl_mem; 

CREATE MULTISET TABLE collectl_mem 
     (
      hostname VARCHAR(60) ,
      date_mem DATE,
      time_mem TIME,
      Tot bigint,
      Used bigint,
      Free bigint,
	  Shared bigint,
	  Buf bigint,
	  Cached bigint,
	  Slab bigint,
	  Map_mem bigint,
	  Anon bigint,
	  Commit_mem bigint,
	  Locked bigint,
	  SwapTot bigint,
	  SwapUsed bigint,
	  SwapFree bigint,
	  SwapIn bigint,
	  SwapOut bigint,
	  Dirty bigint,
	  Clean bigint,
	  Laundry bigint,
	  Inactive bigint,
	  PageIn bigint,
	  PageOut bigint,
	  PageFaults bigint,
	  PageMajFaults bigint,
	  HugeTotal bigint,
	  HugeFree bigint,
	  HugeRsvd bigint,
	  SUnreclaim bigint)
PRIMARY INDEX ( date_mem,time_mem,hostname );

drop table et_collectl_nfs;
drop table wt_collectl_nfs;
drop table uv_collectl_nfs;
drop table collectl_nfs;
drop table myadmin.mylogtablenfs;
release mload collectl_nfs; 

CREATE MULTISET TABLE collectl_nfs 
     (
      hostname VARCHAR(60) ,
      date_nfs DATE,
      time_nfs TIME,
      ReadsS bigint,
      WritesS bigint,
      MetaS bigint,
	  CommitS bigint,
	  Udp bigint,
	  Tcp bigint,
	  TcpConn bigint,
	  BadAuth bigint,
	  BadClient bigint,
	  ReadsC bigint,
	  WritesC bigint,
	  MetaC bigint,
	  CommitC bigint,
	  Retrans bigint,
	  AuthRef bigint)
PRIMARY INDEX ( date_nfs,time_nfs,hostname );

drop table et_collectl_dsk;
drop table wt_collectl_dsk;
drop table uv_collectl_dsk;
drop table collectl_dsk;
drop table myadmin.mylogtabledsk;
release mload collectl_dsk; 

CREATE MULTISET TABLE collectl_dsk
     (
      hostname VARCHAR(60) ,
      date_dsk DATE,
      time_dsk TIME,
      ReadTot bigint,
      WriteTot bigint,
      OpsTot bigint,
	  ReadKBTot bigint,
	  WriteKBTot bigint,
	  KbTot bigint,
	  ReadMrgTot bigint,
	  WriteMrgTot bigint,
	  MrgTot bigint)
PRIMARY INDEX ( date_dsk,time_dsk,hostname );

drop table et_collectl_prc;
drop table wt_collectl_prc;
drop table uv_collectl_prc;
drop table collectl_prc;
drop table myadmin.mylogtableprc;
release mload collectl_prc; 

CREATE MULTISET TABLE collectl_prc 
     (
      hostname VARCHAR(60) ,
      date_prc DATE,
      time_prc TIME,
      PID bigint,
      User_prc varchar(15),
      PR varchar(20),
	  PPID bigint,
	  THRD bigint,
	  S varchar(3),
	  VmSize bigint,
	  VmLck bigint,
	  VmRSS bigint,
	  VmData bigint,
	  VmStk bigint,
	  VmExe bigint,
	  VmLib bigint,
	  CPU bigint,
	  SysT Decimal(10,2),
	  UsrT Decimal(10,2),
	  PCT bigint,
	  --AccumT TIME,
	  RKB bigint,
	  WKB bigint,
	  RKBC bigint,
	  WKBC bigint,
	  RSYS bigint,
	  WSYS bigint,
	  CNCL bigint,
	  MajF bigint,
	  MinF bigint,
	  command varchar(10000))
PRIMARY INDEX ( date_prc,time_prc,hostname,pid);