%LET _CLIENTTASKLABEL='Test Crosstabs - Calculated Variables';
%LET _CLIENTPROCESSFLOWNAME='TY 2017 Programs';
%LET _CLIENTPROJECTPATH='/ncf/projects/osbm/tax_models/shared/eg_projects/TY_2017_Microdata_Analyses.egp';
%LET _CLIENTPROJECTPATHHOST='ncf238au.vsp.sas.com';
%LET _CLIENTPROJECTNAME='TY_2017_Microdata_Analyses.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

TITLE;
TITLE1 "AGI Percentiles by Residency - 2017";
FOOTNOTE;
FOOTNOTE1 "Generated on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%SYSFUNC(TIME(), TIMEAMPM12.))";
TITLE1 "AGI Percentiles by Residency - 2017";

Proc sort data=NCTAX_2017_Calcs out=NCTAX_2017_Calcs_SortByRes;
	By WS_Residency_Status;
	
Proc summary data=NCTAX_2017_Calcs_SortByRes ;
	by WS_Residency_Status;
	var NC_AGI;
	output out=AGI_PCTLS_17 p50=NC_AGI_P50_Y17 p75=NC_AGI_P75_Y17 p90=NC_AGI_P90_Y17 p95=NC_AGI_P95_Y17 p99=NC_AGI_P99_Y17 ;
	weight sample_weight;
	run;
proc transpose data=AGI_PCTLS_17(where=(WS_Residency_Status = 1) drop=_type_  _freq_) Out=Pctl_Fmt_17; 
	run;
Data Pctl_Fmt_17; Set Pctl_Fmt_17; 
	If _name_ = 'NC_AGI_P50_Y17' then call symput('AGI_P50_Y17',Col1);
	If _name_ = 'NC_AGI_P75_Y17' then call symput('AGI_P75_Y17',Col1);
	If _name_ = 'NC_AGI_P90_Y17' then call symput('AGI_P90_Y17',Col1);
	If _name_ = 'NC_AGI_P95_Y17' then call symput('AGI_P95_Y17',Col1);
	If _name_ = 'NC_AGI_P99_Y17' then call symput('AGI_P99_Y17',Col1);
run;
%put macro variable AGI_P50_Y17: &AGI_P50_Y17;
%put macro variable AGI_P75_Y17: &AGI_P75_Y17;
%put macro variable AGI_P90_Y17: &AGI_P90_Y17;
%put macro variable AGI_P95_Y17: &AGI_P95_Y17;
%put macro variable AGI_P99_Y17: &AGI_P99_Y17;

Data NCTAX_2017_Calcs; Set NCTAX_2017_Calcs;
	NC_AGI_Pctl_Grp = .; 
	If 	NC_AGI LE &AGI_P50_Y17 Then NC_AGI_Pctl_Grp = 1;
	Else If NC_AGI LE &AGI_P75_Y17 Then NC_AGI_Pctl_Grp = 2;
	Else If NC_AGI LE &AGI_P90_Y17 Then NC_AGI_Pctl_Grp = 3; 
	Else If NC_AGI LE &AGI_P95_Y17 Then NC_AGI_Pctl_Grp = 4;
	Else If NC_AGI LE &AGI_P99_Y17 Then NC_AGI_Pctl_Grp = 5;
	Else NC_AGI_Pctl_Grp = 6;
run;



Proc Format ;
	value agi_group_fmt
		0 = 'AGI $0 or less'
		1 = 'AGI $1 to $10k'
		2 = 'AGI $10k to $25k'
		3 = 'AGI $25k to $50k'
		4 = 'AGI $50k to $75k'
		5 = 'AGI $75k to $100k'
		6 = 'AGI $100k to $200k'
		7 = 'AGI $200k to $500k'
		8 = 'AGI $500k to $1m'
		9 = 'AGI $1m or more';
	value agi_pctl_fmt
		1 = 'Bottom 50%'
		2 = '50%-75%'
		3 = '75%-90%'
		4 = '90%-95%'
		5 = '95%-99%'
		6 = 'Top 1%';
	value money_groupa_fmt
		Low-0 = '$0 or less'
		1-25000 = '$1 to $25k'
		25001-50000 = '$25k to $50k'
		50001-100000 = '$50k to $100k'
		100001-200000 = '$100k to $200k'
		200001-500000 = '$200k to $500k'
		500001-High = '$500k or more';
	value money_groupb_fmt
	Low-0 = '$0 or less'
	1-100 = '$1 to $100'
	101-250 = '$101 to 250'
	251-500 = '$251 to $500'
	501-1000 = '$501 to $1k'
	1001-2500 = '$1k to $2.5k'
	2501-High = '$2.5k or more';
	value nc_fs_fmt
	1 = 'Single'
	2 = 'MFJ/SS'
	3 = 'MFS'
	4 = 'HoH'
	5 = 'MFJ/SS';
	value res_stat_fmt
	1 = 'Resident'
	2 = 'Part-Year'
	3 = 'Nonresident';
	value biz_filer_fmt
	0 = 'No Biz Income'
	1 = 'Has Biz Income';
	value overpay_fmt
	0 = 'Underpayment'
	1 = 'Not Over/Under'
	2 = 'Overpayment';
	run;

TITLE1 "Percentiles of Variables on D-400 Returns - Full-Year Residents";
Proc Means data=NCTAX_2017_Calcs maxdec=0 Min P1 P5 P10 P25 median mean P75 P90 P95 P99 Max SUM ; 
	where WS_Residency_Status = 1 ;
	weight sample_weight;
	var WS_AM_ADDITIONS WS_AM_DEDUCTIONS WS_AM_NC_STD_ITM WS_AM_QUAL_MORTG WS_AM_REAL_ESTTX NC_RET_MORT_ALWD WS_AM_CHARIT_CONT 
			WS_AM_FRGN_TAX_CR NC_AGI NCTI_Recal_BPro_2017 NCTI_Recal_APro_2017 NC_Tax_Calc_2017 NC_Calc_Credits_Taken_17 NC_NET_TAX_CALC_17;
Run;

Data work.NC_Incomes_2017;
	Set NCTAX_2017_Calcs;
	Keep Record_ID WS_RESIDENCY_STATUS NC_FS_recode NC_AGI Taxpayer Sec_payer Children sample_weight;
Run;
Proc Sort Data=work.NC_Incomes_2017;
	By WS_RESIDENCY_STATUS NC_FS_RECODE;
Run;
	
TITLE1 "Resident AGI Percentiles by Filing Status";
Proc Means data=work.NC_Incomes_2017 maxdec=0 Min P1 P5 P10 P25 median mean P75 P90 P95 P99 Max SUM;
	where WS_RESIDENCY_STATUS = 1;
	weight sample_weight;
	var NC_AGI ;
	By nc_fs_recode;
	format nc_fs_recode nc_fs_fmt.;
Run;
TITLE1 "Resident AGI Percentiles for Elderly MFJ";
Proc Means data=work.NC_Incomes_2017 maxdec=0 Min P1 P5 P10 P25 median mean P75 P90 P95 P99 Max SUM;
	where WS_RESIDENCY_STATUS = 1 and (taxpayer in (2,3) or sec_payer in (2,3)) and nc_fs_recode = 2;
	weight sample_weight;
	var NC_AGI ;
	format nc_fs_recode nc_fs_fmt.;
Run;
TITLE1 "Resident AGI Percentiles for MFJ with Children";
Proc Means data=work.NC_Incomes_2017 maxdec=0 Min P1 P5 P10 P25 median mean P75 P90 P95 P99 Max SUM;
	where WS_RESIDENCY_STATUS = 1 and children ne 0 and nc_fs_recode = 2;
	weight sample_weight;
	var NC_AGI ;
	format nc_fs_recode nc_fs_fmt.;
Run;
TITLE1 "Resident Filers by AGI Percentiles- 2017";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	WHERE WS_Residency_Status = 1 ;
	VAR SAMPLE_WEIGHT;
	Format NC_AGI_Pctl_Grp agi_pctl_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS NC_AGI_Pctl_Grp /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Pctl_Grp=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*SAMPLE_WEIGHT=' '*SUMWGT=' '  All*sample_weight=' '*SUMWGT=' ' /box='Filers'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "All Residents D-400 AGI by AGI Percentile";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	WHERE WS_RESIDENCY_STATUS = 1 ;
	VAR NC_AGI;
	Format NC_AGI_Pctl_Grp agi_pctl_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS NC_AGI_Pctl_Grp WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Pctl_Grp=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_AGI=' '*SUM=' ' All*NC_AGI=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Resident Filers by AGI  - 2017";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	WHERE WS_Residency_Status = 1 ;
	VAR SAMPLE_WEIGHT;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*SAMPLE_WEIGHT=' '*SUMWGT=' '  All*sample_weight=' '*SUMWGT=' ' /box='Filers'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "All Residents D-400 AGI by AGI";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	WHERE WS_RESIDENCY_STATUS = 1 ;
	VAR NC_AGI;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS NC_AGI_Group WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_AGI=' '*SUM=' ' All*NC_AGI=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "All Filers by Residency";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	VAR sample_weight;
	Format NC_AGI_Group agi_group_fmt. WS_RESIDENCY_STATUS res_stat_fmt.;
	CLASS WS_RESIDENCY_STATUS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_RESIDENCY_STATUS=' '*sample_weight=' '*SUMWGT=' ' All*sample_weight=' '*SUMWGT=' ' /box='Returns'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "AGI of Returns by Residency";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	VAR nc_agi;
	Format NC_AGI_Group agi_group_fmt. WS_RESIDENCY_STATUS res_stat_fmt.;
	CLASS WS_RESIDENCY_STATUS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_RESIDENCY_STATUS=' '*nc_agi=' '*SUM=' ' all*nc_agi=' '*SUM=' '/box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "High-Level Calculated NC Resident Net Tax";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_NET_TAX_17;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_NET_TAX_17=' '*SUM=' ' All*NC_NET_TAX_17=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Net Difference - Calculated vs. Reported Resident NC Net Tax";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR DIFF_NC_NET_TAX_17;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*DIFF_NC_NET_TAX_17=' '*SUM=' ' All*DIFF_NC_NET_TAX_17=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Components-Calculated NC Resident Net Tax";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_NET_TAX_CALC_17;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_NET_TAX_CALC_17=' '*SUM=' ' All*NC_NET_TAX_CALC_17=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Components-Calculated Net Tax by Residency";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	VAR NC_NET_TAX_CALC_17;
	Format NC_AGI_Group agi_group_fmt. WS_Residency_Status res_stat_fmt.;
	CLASS NC_AGI_Group WS_Residency_Status /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_Residency_Status=' '*NC_NET_TAX_CALC_17=' '*SUM=' ' All*NC_NET_TAX_CALC_17=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Net Difference - High-Level vs. Components-Calculated NC Net Tax";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR DIFF_NC_NET_TAX_17_HL_BC;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*DIFF_NC_NET_TAX_17_HL_BC=' '*SUM=' ' All*DIFF_NC_NET_TAX_17_HL_BC=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "High-Level Calculated NC Resident Tax Computation";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_GROSS_TAX_17;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_GROSS_TAX_17=' '*SUM=' ' All*NC_GROSS_TAX_17=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Components-Calculated NC Resident Tax Computation";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_Tax_Calc_2017;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_Tax_Calc_2017=' '*SUM=' ' All*NC_Tax_Calc_2017=' '*SUM=' '/box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "High-Level Calculated NC Resident Credits Taken";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_Credits_Taken_17;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_Credits_Taken_17=' '*SUM=' ' All*NC_Credits_Taken_17=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Components-Calculated NC Resident Credits Taken";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_Calc_Credits_Taken_17;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_Calc_Credits_Taken_17=' '*SUM=' ' All*NC_Calc_Credits_Taken_17=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Reported NC Resident D-400 Additions";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR WS_AM_ADDITIONS;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*WS_AM_ADDITIONS=' '*SUM=' ' All*WS_AM_ADDITIONS=' '*SUM=' '/box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Components-Calculated NC Resident D-400 Additions";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_Additions_2017;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_Additions_2017=' '*SUM=' ' All*NC_Additions_2017=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Reported NC Resident D-400 Deductions";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR WS_AM_DEDUCTIONS;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*WS_AM_DEDUCTIONS=' '*SUM=' ' All*WS_AM_DEDUCTIONS=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Components-Calculated NC Resident D-400 Deductions";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_Deductions_2017;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_Deductions_2017=' '*SUM=' ' All*NC_Deductions_2017=' '*SUM=' '/box='Amount'	;
	WEIGHT sample_weight;
RUN;
TITLE1 "Reported NC Resident D-400S Itemized Deductions - 2017";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1 and WS_FLAG_DEDUCT_TYPE = 2;
	VAR WS_AM_TOT_NC_ITMDED;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*WS_AM_TOT_NC_ITMDED=' '*SUM=' ' All*WS_AM_TOT_NC_ITMDED=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Components-Calculated NC Resident D-400S Itemized Deductions - 2017";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1 and WS_FLAG_DEDUCT_TYPE = 2;
	VAR NC_ITEM_DED_2017;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_ITEM_DED_2017=' '*SUM=' ' All*NC_ITEM_DED_2017=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN;
TITLE1 "NC Resident Itemizers with Larger Default St. Ded";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1 and WS_FLAG_DEDUCT_TYPE = 2 and NC_ITEM_DED_2017 < NC_2017D_SD ;
	VAR sample_weight;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*sample_weight=' '*SUMWGT=' ' All*sample_weight=' '*SUMWGT=' ' /box='Filers' ;
	WEIGHT sample_weight;
RUN;
TITLE1 "Resident State Itemizers - 2017";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	WHERE WS_Residency_Status = 1 and WS_FLAG_DEDUCT_TYPE = 2;
	VAR SAMPLE_WEIGHT;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*SAMPLE_WEIGHT=' '*SUMWGT=' '  All*sample_weight=' '*SUMWGT=' ' /box='Filers'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "NC Resident Net Tax - 2014 Policy";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma14.	;
	Where WS_Residency_Status = 1;
	VAR NC_NET_TAX_CALC_14;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_NET_TAX_CALC_14=' '*SUM=' ' All*NC_NET_TAX_CALC_14=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "NC Net Tax by Residency - 2014 Policy";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma14.	;
	VAR NC_NET_TAX_CALC_14;
	Format NC_AGI_Group agi_group_fmt. WS_Residency_Status res_stat_fmt.;
	CLASS NC_AGI_Group WS_Residency_Status /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_Residency_Status=' '*NC_NET_TAX_CALC_14=' '*SUM=' ' All*NC_NET_TAX_CALC_14=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "NC Resident Net Tax - 2015 Policy";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_NET_TAX_CALC_15;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_NET_TAX_CALC_15=' '*SUM=' ' All*NC_NET_TAX_CALC_15=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "NC Net Tax by Residency - 2015 Policy";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	VAR NC_NET_TAX_CALC_15;
	Format NC_AGI_Group agi_group_fmt. WS_Residency_Status res_stat_fmt.;
	CLASS NC_AGI_Group WS_Residency_Status /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_Residency_Status=' '*NC_NET_TAX_CALC_15=' '*SUM=' ' All*NC_NET_TAX_CALC_15=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "NC Resident Net Tax - 2019 Policy";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1;
	VAR NC_NET_TAX_CALC_19;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_NET_TAX_CALC_19=' '*SUM=' ' All*NC_NET_TAX_CALC_19=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "NC Net Tax by Residency - 2019 Policy";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	VAR NC_NET_TAX_CALC_19;
	Format NC_AGI_Group agi_group_fmt. WS_Residency_Status res_stat_fmt.;
	CLASS NC_AGI_Group WS_Residency_Status /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_Residency_Status=' '*NC_NET_TAX_CALC_19=' '*SUM=' ' All*NC_NET_TAX_CALC_19=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Resident State Itemizers - 2019 Policy";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	WHERE WS_Residency_Status = 1 and NC_2019_ID_IND = 2;
	VAR SAMPLE_WEIGHT;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*SAMPLE_WEIGHT=' '*SUMWGT=' '  All*sample_weight=' '*SUMWGT=' ' /box='Filers'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "NC Resident D-400S Itemized Deductions - 2019 Policy";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1 and NC_2019_ID_IND = 2;
	VAR NC_ITEM_DED_2017;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*NC_ITEM_DED_2017=' '*SUM=' ' All*NC_ITEM_DED_2017=' '*SUM=' ' /box='Amount'	;
	WEIGHT sample_weight;
RUN;
TITLE1 "Impact of Excluding Medical Expenses Deduction";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	VAR DIFF_Net_Tax_17_ExMED;
	Format NC_AGI_Group agi_group_fmt. OverUnder_Ind overpay_fmt.;
	CLASS NC_AGI_Group OverUnder_Ind /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			OverUnder_Ind=' '*DIFF_Net_Tax_17_ExMED=' '*SUM=' '  All*DIFF_Net_Tax_17_ExMED=' '*SUM=' ' /box='Filers'	;
	WEIGHT sample_weight;
RUN; 
TITLE1 "Number of Exemptions Resident Returns";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1 ;
	VAR Num_Exem;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*Num_Exem=' '*SUM=' ' All*Num_Exem=' '*SUM=' ' /box='Number'	;
	WEIGHT sample_weight;
RUN;
TITLE1 "Senior Exemptions Resident Returns";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	Where WS_Residency_Status = 1 ;
	VAR Seniors;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*Seniors=' '*SUM=' ' All*Seniors=' '*SUM=' ' /box='Number'	;
	WEIGHT sample_weight;
RUN;
TITLE1 "Resident Returns w/ Qualifying Children";
PROC TABULATE
DATA=NCTAX_2017_Calcs Format=Comma15.	;
	WHERE WS_Residency_Status = 1 and NC_Qual_Child NE 0;
	VAR SAMPLE_WEIGHT;
	Format NC_AGI_Group agi_group_fmt. WS_FILING_STATUS nc_fs_fmt.;
	CLASS WS_FILING_STATUS /	ORDER=UNFORMATTED MISSING;
	CLASS NC_AGI_Group /	ORDER=UNFORMATTED MISSING;
	TABLE 	/* Row Dimension */
			NC_AGI_Group=' ' All,
			/* Column Dimension */
			WS_FILING_STATUS=' '*SAMPLE_WEIGHT=' '*SUMWGT=' '  All*sample_weight=' '*SUMWGT=' ' /box='Filers'	;
	WEIGHT sample_weight;
RUN; 




%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

