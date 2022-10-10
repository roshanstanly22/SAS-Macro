%macro chklisttosas(macroname=,in_file=);

/*Importing checklist file into sas dataset*/
 %let file1 = %kscan(%sysfunc(kcompress(&in_file,'"')),-1,%str(.));
 %if &file1 = %klowcase(xlsx) or &file1 =  %klowcase(xlsm)%then %do; %let file=xlsx ;%end;
    %else  %let file=&file1;
    %if  &file1 = %klowcase(xls) or &file1 = %klowcase(xlsx) %then %do;
	filename infile &in_file;
        proc import datafile=infile
		    out=list1
		    dbms=&file
		    replace;
		    getnames=yes;
       run;
    %end;
%let nobs = &sysnobs.;

/*Handling when multiple asserts within single testcase*/
data list1a;
  set list1;
  length exp1 exp2 $10000.;
  exp1 = tranwrd(expected_result,"!","@#@");
  exp2 =translate(exp1,'!','0A'x,'0D'x);
  var = countw(exp2,"!");
  call symput(cats("n",strip(put(_n_,best.))),strip(put(_n_,best.)));
  call symput(cats("v",strip(put(_n_,best.))),strip(put(var,best.)));
run;

/*Appropriate Assert macros being called, can be updated if more macros required.
Structing the test Program with comments and statements*/
data list2(keep=progline);
  set list1a;
  array dumvar[50] $10000;
  array dvar[50] $10000;
  array resvar[50] $10000.;
  length progline result2 $10000.;
  logic1 = tranwrd(substr(strip(testcase),2),"?",",");
  logic1= compbl(compress(logic1,'0D0A'x));
 
  %do i = 1 %to &nobs.;

  if _N_ eq &&n&i. then do;
    %if &&v&i. gt 1 %then %do;
	  do i = 1 to &&v&i.;

	    dumvar[i] = strip(substr(scan(exp2,i,"!"),3));
if substr(strip(dumvar[i]),length(strip(dumvar[i])),1) eq "." then resvar[i] =  substr(strip(dumvar[i]),1,length(strip(dumvar[i]))-1);
        else resvar[i] = dumvar[i];
        if find(resvar[i],"log message","i") then do;
          dvar[i] = substr(resvar[i],find(resvar[i],"log message","i")+14);
	       dvar[i] = tranwrd(dvar[i],'"',"");
dvar[i] = cats('%assertLogMsg(i_logMsg=%str(',tranwrd(tranwrd(tranwrd (tranwrd(dvar[i],"\","\\"),"(","\("),")","\)"),"^","\^"),'))');
            end;
else if find(resvar[i],"Derive the dataset in a separate program and compare both the datasets","i") then do;
dvar[i] = cats('%assertColumns(i_actual= , i_expected= ,i_desc=%str(',strip(logic1),'), i_allow=LENGTH)' );
          end;
          else do;
            dvar[i] = resvar[i];
          end;
    end;
    result2 = catx('0A'x,of dvar:);
    %end;
    %else %do;
	 if substr(strip(expected_result),length(strip(expected_result)),1) eq "." then result1 = substr(strip(expected_result),1,length(strip(expected_result))-1);
        else result1 = expected_result;
        result1= compbl(compress(result1,'0D0A'x));
        if find(result1,"log message","i") then do;
           result2 = substr(result1,find(result1,"log message","i")+14);
	   result2 = tranwrd(result2,'"',"");
result2 = cats('%assertLogMsg(i_logMsg=%str(',tranwrd(tranwrd(tranwrd (tranwrd(result2,"\","\\"),"(","\("),")","\)"),"^","\^"),'))');
      end;
 else if find(result1,"Derive the dataset in a separate program and compare both the datasets","i") then do;
result2 = cats('%assertColumns(i_actual= , i_expected= , i_desc=%str(',strip(logic1),'), i_allow=LENGTH)' );
      end;
      else do;
        result2 = result1;
      end;
	%end;
  end;
  %end;
  result2 = tranwrd(result2,"@#@","!");
 
  progline = cat("/*Check ",cats(_n_),"*/");
  output;
  progline = cat('%initTestcase(i_object=',"&macroname..sas, ",'i_desc=%str(',strip(logic1),'))');
  output;
if find(expected_result,"Derive the dataset in a separate program and compare both the datasets") then do;
    progline = "/*<DERIVE THE DATASET MANUALLY HERE>*/";
    output;
    progline = strip(macro_check);
    output;
  end;
  else do;
    progline = strip(macro_check);
    output;
  end;
  progline = '%endTestcall()';
  output;
  progline = strip(result2);
  output;
  progline = '%endTestcase();';
  output;
  progline = "";
  output;
run;

/*Header part for the sasunit tes program*/
data list3;
  length progline $10000.;
  progline = "/***********************************************************************************************************************";
  output;
  Progline = "Program Name:                &macroname._sasunit_test";
  output;
  Progline = "SAS Version:                 SAS V9.4";
  output;
  Progline = "Short Description:           Program to validate the reporting macro &macroname..";
  output;
  Progline = "Author:                      <Author>";
  output;
  Progline = "Date:                        <Date of development>";
  output;
  Progline = "Input:                       <Add input datasets here>";
  output;
  Progline = "Output:                      HTML file for sas unit test documentation";
  output;
  Progline = "";
  output;
  Progline = "***********************************************************************************************************************/";
  output;
  Progline = "";
  output;
  progline = cat('%initScenario(i_desc=Tests for ',"&macroname..sas);");
  output;
run;

data list4;
  length progline $10000.;
  progline = '%endScenario;';
  output;
run;

data list5;
  set list3 list2 list4;
run;

/*Path and file name of the sasunit program*/
filename sascode "&path.\&macroname._sasunit_test.sas";

data _null_;
  set list5;
  file sascode;
  put progline;
run;

%mend chklisttosas;
