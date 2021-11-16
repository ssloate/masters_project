/* SAS macro that duplicates the Excel RANDBETWEEN function */
%macro RandBetween(min, max);
   (&min + floor((1+&max-&min)*rand("uniform")))
%mend;
PROC SQL;
Create Table work.NCTAX_2017_Calcs AS
	Select		
		RECORD_ID,
		COUNTER_VAR,
		WS_Residency_Status,
		WS_FLAG_PARTYR_RES,
		WS_FLAG_PARTYR_RES_SP,
		AGICODE,
		WS_FILING_STATUS,
	/* NC Filing Status Recode */
		(Case When WS_FILING_STATUS < 5 Then WS_FILING_STATUS Else 2 End) 
			Format 1. As NC_FS_Recode,
		AM_TOTAL_INCOME,
		AM_ADJTED_GRS_INC,
		AM_TOT_POS_INC,
	/* Consolidate NC AGI Fields */
		(Case When WS_AM_AGI_FED_FOR_QUERIES NE 0 Then WS_AM_AGI_FED_FOR_QUERIES Else 0 end) Format=Bestx10. As NC_AGI,
	/* NC AGI Minus Fed AGI */
		Calculated NC_AGI - AM_ADJTED_GRS_INC Format=Bestx12. As AGI_DIFF,

		TAXPAYER,
		SEC_PAYER,
		Children,
		/* Seniors Represented in Tax Return */
			(Case when Taxpayer in (2,3) Then 1 Else 0 End) + (Case when Sec_Payer in (2,3) Then 1 Else 0 End) + Parents
			Format=Bestx2. As Seniors,

	/* AGI_Group */
		(CASE  
        	WHEN CALCULATED NC_AGI <= 0 THEN 0
            WHEN CALCULATED NC_AGI <= 10000 THEN 1
            WHEN CALCULATED NC_AGI <= 25000 THEN 2
            WHEN CALCULATED NC_AGI <= 50000 THEN 3
            WHEN CALCULATED NC_AGI <= 75000 THEN 4
            WHEN CALCULATED NC_AGI <= 100000 THEN 5
            WHEN CALCULATED NC_AGI <= 200000 THEN 6
            WHEN CALCULATED NC_AGI <= 500000 THEN 7
            WHEN CALCULATED NC_AGI <= 1000000 THEN 8
            ELSE 9 END) FORMAT=BESTX3. AS NC_AGI_Group, 
	/* AGI_Group B */
		(CASE  
            WHEN CALCULATED NC_AGI <= 0 THEN 0
            WHEN CALCULATED NC_AGI <= 50000 THEN 1
            WHEN CALCULATED NC_AGI <= 100000 THEN 2
            WHEN CALCULATED NC_AGI <= 500000 THEN 3
            WHEN CALCULATED NC_AGI > 500000 THEN 4 END) FORMAT=BESTX3. AS NC_AGI_GroupB,
		AM_TAX_SS_BENE,
		AM_SS_BENEFITS,
		AM_TOTAL_ADJUST,
		AM_TOT_IRA_DIST,
		AM_TXBLE_IRA_DIST,
		AM_TXBLE_PENSION,

	/* Investment Income */
		AM_DIV_INC + AM_Tax_Int_Income + AM_TX_Exmpt_Int + AM_CTL_Gain_Loss_P - AM_CTL_Gain_Loss_M
			Format=BestX11. As TOT_Invest_Inc,

	/* Business Income Items */
		RENTAL_ROYAL_PROF - RENTAL_ROYAL_LOSS FORMAT=BESTX11. AS TOT_RENT_ROY_INC,
		-PARTNER_SCORP_LOSS + PARTNER_SCORP_INC FORMAT=BESTX11. AS TOT_PART_SCORP_INC,
		AM_PROFIT_LOSS1 + AM_PROFIT_LOSS2 + AM_PROFIT_LOSS3 FORMAT=BESTX11. AS TOT_SCH_C_INC,
		Calculated TOT_RENT_ROY_INC + Calculated TOT_PART_SCORP_INC + Calculated TOT_SCH_C_INC FORMAT=BESTX11. AS TOT_BIZ_INC,		


		WS_AM_PY_NRES_FACTOR, 
		WS_AM_PY_NRES_NC_INC, 
		WS_AM_PY_NRES_TOT_INC,

	/* Federal Itemized Deductions */
		WS_FED_STDDED_FLAg,
		TOT_MED_EXP,
		TOT_MED_DED,
		ST_LOC_INC_TAX,
		REAL_EST_TAX,
		/* Total Home Mortgage Interest */
			FIN_HOME_MORT_INT + PS_HOME_MORT_INT FORMAT=BESTX8. AS TOT_MORT_INT,
		DED_POINTS,
		DED_INV_INT,
		TOT_CONTRIB,
		TOT_CAS_THEFT_LOSS,
		GROSS_LIM_MISC_DED,
		NET_LIM_MISC_DED,
		OTHER_NONLIM_MISC,
		TOT_ITEM_DED,

	/*Federal Credits */
		AM_Child_Tax_Cr,
		AM_AD_Child_Tax_Cr,
		/* Total Federal Child Credit */
	        AM_Child_Tax_Cr + AM_AD_Child_Tax_Cr FORMAT=bestx5. LABEL="Combined Federal Child Credit" As Tot_Fed_Child_CR,
		AM_EARNED_INCOME,
		Am_Child_Care,
		Qualified_Exp,
		Emp_Prov_Benefits,

/* NC Tax Calculation Variables */
	WS_AM_NCTI_CALC,

	/* NC 2014 Standard Deduction */
        (CASE  When WS_AM_NC_STD_ITM = 0 Then 0
         	WHEN WS_FILING_STATUS = 1 Then 7500
         	WHEN WS_FILING_STATUS in (2,5) Then 15000
         	WHEN WS_FILING_STATUS = 3 Then 7500
         	WHEN WS_FILING_STATUS = 4 Then 12000 Else 7500 END) 
		FORMAT=bestx5. LABEL="NC 2014 Standard Deduction" AS NC_2014D_SD,

		/* NC 2015 Standard Deduction */
        (CASE  When WS_AM_NC_STD_ITM = 0 Then 0
         	WHEN WS_FILING_STATUS = 1 Then 7750
         	WHEN WS_FILING_STATUS in (2,5) Then 15500
         	WHEN WS_FILING_STATUS = 3 Then 7750
         	WHEN WS_FILING_STATUS = 4 Then 12400 Else 7750 END) 
		FORMAT=bestx5. LABEL="NC 2014 Standard Deduction" AS NC_2015D_SD,

		/* NC 2016 Standard Deduction */
        (CASE  When WS_AM_NC_STD_ITM = 0 Then 0
         	WHEN WS_FILING_STATUS = 1 Then 8250
         	WHEN WS_FILING_STATUS in (2,5) Then 16500
         	WHEN WS_FILING_STATUS = 3 Then 8250
         	WHEN WS_FILING_STATUS = 4 Then 13200 Else 8250 END) 
		FORMAT=bestx5. LABEL="NC 2016 Standard Deduction" AS NC_2016D_SD,

		/* NC 2017-18 Standard Deduction */
        (CASE  When WS_AM_NC_STD_ITM = 0 Then 0
         	WHEN WS_FILING_STATUS = 1 Then 8750
         	WHEN WS_FILING_STATUS in (2,5) Then 17500
         	WHEN WS_FILING_STATUS = 3 Then 8750
         	WHEN WS_FILING_STATUS = 4 Then 14000 Else 8750 END) 
		FORMAT=bestx5. LABEL="NC 2016 Standard Deduction" AS NC_2017D_SD,

		/* NC 2019 Standard Deduction */
        (CASE  When WS_AM_NC_STD_ITM = 0 Then 0
         	WHEN WS_FILING_STATUS = 1 Then 10000
         	WHEN WS_FILING_STATUS in (2,5) Then 20000
         	WHEN WS_FILING_STATUS = 3 Then 10000
         	WHEN WS_FILING_STATUS = 4 Then 15000 Else 10000 END) 
		FORMAT=bestx5. LABEL="NC 2019 Standard Deduction" AS NC_2019D_SD,



		/* Number of exemptions */
			(Case when unmatched = 1 Then Min(1,TAXPAYER) + Min(Sec_payer,1) + Min(Children,9) 
					+ Min(Child_away,9) + Min(parents,9) + Min(Other_child,9) + Min(Others,9) 
				When unmatched = 0 Then 
					(Case When  WS_FILING_STATUS in (1,3,5) Then 1 + WS_CNT_CHLD_CR
						When WS_FILING_STATUS = 2 Then 2 + WS_CNT_CHLD_CR
						When WS_FILING_STATUS = 4 Then 1 + Min(1,WS_CNT_CHLD_CR) Else 1 End)
				Else 0 End) Format 2. as Num_Exem,

	/* Summary NC Additions and Deductions */
	WS_AM_ADDITIONS,
	WS_AM_DEDUCTIONS,
	WS_AM_NC_STD_ITM,

	/* Payments vs. Liability */
	WS_AM_NET_TAX_DUE,
	WS_AM_TAX_WH,
	WS_AM_TAX_WH_SP,
	WS_AM_ESTIM_PYMT,
	WS_AM_EXTEN_PYMT,
	WS_AM_TOT_PREPYMT,
	WS_AM_TAX_DUE_PRE_PI,
	WS_AM_OVERPAYMT,
	WS_AM_CALC_REFUND,

	/* Over/Under-Payment Indicator */
	(Case When WS_AM_OVERPAYMT > 10 Then 2 
		When WS_AM_TAX_DUE_PRE_PI > 10 Then 0
		Else 1 End) Format 1. as OverUnder_ind,
	/* Recalculated Over/UnderPayment */
		WS_AM_NET_TAX_DUE - WS_AM_TOT_PREPYMT Format=Bestx10. As NC_Tax_Minus_Prepay,
	/* Over/Under-Payment Indicator Recalculated */
		(Case When Calculated NC_Tax_Minus_Prepay > 10 Then 0
			When Calculated NC_Tax_Minus_Prepay < -10 Then 2
			Else 1 End) Format 1. as OverUnder_ind_Calc,

	/* Over/Under-Payment Estimates If No Enhanced Withholding Rate */
		/* Total Prepayments If No Enhanced Withholding Rate */
		WS_AM_TOT_PREPYMT - Max(0,(WS_AM_TAX_WH + WS_AM_TAX_WH_SP) * 0.1/5.85)
			Format=Bestx10. As WS_AM_TOT_PREPYMT_ALT,
		/* Recalculated Over/UnderPayment */
		WS_AM_NET_TAX_DUE - Calculated WS_AM_TOT_PREPYMT_Alt Format=Bestx10. As NC_Tax_Minus_Prepay_Alt,
		/* Over/Under-Payment Indicator Recalculated */
		(Case When Calculated NC_Tax_Minus_Prepay_Alt > 10 Then 0
			When Calculated NC_Tax_Minus_Prepay_Alt < -10 Then 2
			Else 1 End) Format 1. as OverUnder_ind_Calc_Alt,


	/* Business-Income Filer Indicator (Based on Estimated Payments) */
		(Case When WS_AM_ESTIM_PYMT GE 10 Then 1 Else 0 End) 
			Format 1. as Biz_Filer,
	/* Primarily-Withholding Filer Indicator (vs. Estimated Payments) */
		(Case When WS_AM_TAX_WH + WS_AM_TAX_WH_SP > WS_AM_ESTIM_PYMT and WS_AM_TAX_WH + WS_AM_TAX_WH_SP > 10 Then 1 Else 0 End) 
			Format 1. as PrimWith_Filer,


	WS_PRO_PCT,
	/* Adjusted Proration Percentage */
		(Case
			When WS_Residency_Status = 1 and WS_PRO_PCT > 10 Then 1
			When WS_Residency_Status = 1 and WS_PRO_PCT = 0 and WS_AM_NCTI_CALC NE 0 Then 1
			Else WS_PRO_PCT End)	Format=8.5 as ADJ_PRO_PCT,
	/* 2013 Proration Adjustment */
		(Case When ws_residency_status = 3 Then
			(Case when 200000 < Calculated NC_AGI LE 500000 Then Calculated ADJ_PRO_PCT * (15.3/16.2)
				when 500000 < Calculated NC_AGI LE 1000000 Then Calculated ADJ_PRO_PCT * (6.9/8.5)
				When Calculated NC_AGI > 1000000 Then Calculated ADJ_PRO_PCT * (2.08/2.47) Else Calculated ADJ_PRO_PCT End)
			else Calculated ADJ_PRO_PCT end) Format=8.5 as ADJ_PRO_PCT_13,
	/* 2014 Proration Adjustment */
		(Case When ws_residency_status = 3 and Calculated NC_AGI > 1000000 Then Calculated ADJ_PRO_PCT * (1.91/2.47)
			else Calculated ADJ_PRO_PCT end) Format=8.5 as ADJ_PRO_PCT_14,



/* Net Income Tax Calculation - 2017 Policy - High-Level Variables */
		/* NC 2017 Taxable Income Before Proration*/
		CALCULATED NC_AGI + Abs(WS_AM_ADDITIONS) - Abs(WS_AM_DEDUCTIONS) - 
			(Abs(WS_AM_TOT_NC_ITMDED)* ABS(WS_FLAG_DEDUCT_TYPE-1) + Calculated NC_2017D_SD * ABS(WS_FLAG_DEDUCT_TYPE-2))
			Format=Bestx10. As NC_TAXABLE_INCOME_BPRO_17,
		/* NC 2017 Taxable Income After Proration*/
		Calculated NC_TAXABLE_INCOME_BPRO_17 * Calculated ADJ_PRO_PCT
			Format=Bestx10. As NC_TAXABLE_INCOME_APRO_17,
		/* NC 2017 Gross Calculated Tax Liability */
		Max(0,Calculated NC_TAXABLE_INCOME_APRO_17 * .05499)
			Format=Bestx10. As NC_GROSS_TAX_17,
		/* Credits Taken */
		Min(Calculated NC_GROSS_TAX_17, WS_AM_TAX_CREDIT)
			Format=Bestx8. As NC_Credits_Taken_17,
		/* NC Net Tax 2017 Policy */	
		Max(0,Calculated NC_GROSS_TAX_17 - Calculated NC_Credits_Taken_17)
			Format=Bestx10. As NC_NET_TAX_17,
		/* Calculated vs. Reported 2017 Net Tax */
		Calculated NC_NET_TAX_17 - Max(0,abs(WS_AM_TAX_DUE) - abs(WS_AM_TAX_CREDIT))
			Format=Bestx10. As DIFF_NC_NET_TAX_17,



/* NC Additions to AGI */
		WS_AM_NON_NC_INT,
		WS_AM_DMST_PROD,
		WS_AM_BONUS_DPR_17,
		WS_AM_SEC_179_17,
		WS_AM_OTHER_ADDITNS,


	/* Recalculated NC Additions */
		Abs(WS_AM_NON_NC_INT) + Abs(WS_AM_DMST_PROD) + Abs(WS_AM_BONUS_DPR_17) + Abs(WS_AM_SEC_179_17) + Abs(WS_AM_OTHER_ADDITNS)
			Format=Bestx10. as NC_Additions_2017,

						


/* NC Deductions from AGI */
		WS_AM_ST_REFND_ON_FED,
		WS_AM_US_NC_INT,
		WS_AM_SOC_SEC_RR,
		WS_AM_RET_BEN_BAILEY_SET,
		WS_AM_BONUS_DPR_TOTAL,
		WS_AM_SEC_179_12,
		WS_AM_SEC_179_13,
		WS_AM_SEC_179_14,
		WS_AM_SEC_179_15,
		WS_AM_SEC_179_16,

	/* Total Section 179 Deductions, including a correction for erroneously high 2015 amounts */
		Abs(WS_AM_SEC_179_16) + Abs(WS_AM_SEC_179_12) + Abs(WS_AM_SEC_179_13) + Abs(WS_AM_SEC_179_14) + ABS(WS_AM_SEC_179_15)
			Format=Bestx8. as NC_SEC_179_TOT,
		WS_AM_OTHER_DEDUCTS,
	/* Recalculated NC Deductions from AGI */
		Abs(WS_AM_ST_REFND_ON_FED) +	Abs(WS_AM_US_NC_INT) + Abs(WS_AM_SOC_SEC_RR) + Abs(WS_AM_RET_BEN_BAILEY_SET) +	Abs(WS_AM_BONUS_DPR_TOTAL) +
			Calculated NC_SEC_179_TOT + Abs(WS_AM_OTHER_DEDUCTS) Format=Bestx10. as NC_Deductions_2017,
	/* Difference between reported and calculated NC deductions */
		Calculated NC_Deductions_2017 - WS_AM_DEDUCTIONS Format=Bestx8. as NC_Deductions_2017_Diff,



/* NC Itemized Deductions */
	WS_FLAG_DEDUCT_TYPE,
	WS_AM_QUAL_MORTG,
	WS_AM_REAL_ESTTX,
	WS_AM_TOT_MORTAX,
	WS_AM_ALL_MORTAX,
	/* Recalculated Allowed Mortgage & Real Estate Taxes */
		Min(20000,Abs(WS_AM_QUAL_MORTG) + Abs(WS_AM_REAL_ESTTX))
			Format=Bestx6. as NC_RET_MORT_ALWD,
	WS_AM_CHARIT_CONT,
	WS_AM_MED_DEN_EX,
	WS_AM_CLAIMRIGHT,
	WS_AM_TOT_NC_ITMDED,


	/* Recalculated 2017 NC Itemized Deduction */
		Min(20000,WS_AM_QUAL_MORTG + ABS(WS_AM_REAL_ESTTX)) + WS_AM_CHARIT_CONT + WS_AM_MED_DEN_EX + WS_AM_CLAIMRIGHT
			Format=Bestx9. as NC_ITEM_DED_2017,

	/* Recalculated 2015 NC Itemized Deduction */
		(Case when Calculated NC_ITEM_DED_2017 > 0 Then Min(20000, WS_AM_QUAL_MORTG + ABS(WS_AM_REAL_ESTTX)) + WS_AM_CHARIT_CONT + WS_AM_MED_DEN_EX 
			Else Min(20000, REAL_EST_TAX + FIN_HOME_MORT_INT + PS_HOME_MORT_INT + DED_POINTS) + TOT_CONTRIB + TOT_MED_DED End)
			Format=Bestx9. as NC_ITEM_DED_2015,

		/* NC 2015-Policy Itemized Deduction Indicator */
		(Case When WS_FLAG_DEDUCT_TYPE = 2 
				OR (WS_FLAG_DEDUCT_TYPE = 1 AND (Calculated NC_2016D_SD > Calculated NC_ITEM_DED_2015 > Calculated NC_2015D_SD)) Then 2 Else 1 End)
			FORMAT=1. LABEL="NC 2015-Policy Itemized Deduction Indicator" AS NC_2015_ID_IND,

	/* Recalculated 2014 NC Itemized Deduction */
		(Case when Calculated NC_ITEM_DED_2017 > 0 Then Min(20000, WS_AM_QUAL_MORTG + ABS(WS_AM_REAL_ESTTX)) + WS_AM_CHARIT_CONT
			Else Min(20000, REAL_EST_TAX + FIN_HOME_MORT_INT + PS_HOME_MORT_INT + DED_POINTS) + TOT_CONTRIB End)
			Format=Bestx9. as NC_ITEM_DED_2014,

	/* NC 2014-Policy Itemized Deduction Indicator */
		(Case When (WS_FLAG_DEDUCT_TYPE = 2  And Calculated NC_ITEM_DED_2014 > Calculated NC_2014D_SD) 
				OR (WS_FLAG_DEDUCT_TYPE = 2  And Calculated NC_ITEM_DED_2017 < Calculated NC_2017D_SD)
				OR (WS_FLAG_DEDUCT_TYPE = 1 AND (Calculated NC_2017D_SD > Calculated NC_ITEM_DED_2014 > Calculated NC_2014D_SD)) Then 2 Else 1 End)
			FORMAT=1. LABEL="NC 2014-Policy Itemized Deduction Indicator" AS NC_2014_ID_IND,


		/* Recalculated 2017 NC Itemized Deduction w/o Medical Expenses Deduction */
		Min(20000,WS_AM_QUAL_MORTG + ABS(WS_AM_REAL_ESTTX)) + WS_AM_CHARIT_CONT + WS_AM_CLAIMRIGHT
			Format=Bestx9. as NC_ITEM_DED_2017_ExMED,

	/* NC 2017 Itemized Deduction Indicator w/o Medical Expenses Deduction*/
		(Case When (WS_FLAG_DEDUCT_TYPE = 2 AND (Calculated NC_ITEM_DED_2017_ExMED > Calculated NC_2017D_SD)) 
				OR (WS_FLAG_DEDUCT_TYPE = 2 AND Calculated NC_ITEM_DED_2017 < Calculated NC_2017D_SD)  Then 2 Else 1 End)
			FORMAT=1. LABEL="NC 2017 Itemized Deduction Indicator w/o MED" AS NC_2017_ExMED_ID_IND,

	/* EDIT MEDICAL EXPENSE CALCULATIONS TO INCORPORATE UNMATCHED RETURNS */

	/* Medical Expenses Deduction at 10% AGI Limit */
		Max(0, TOT_MED_EXP - Max(0,calculated NC_AGI*0.1))
			Format=Bestx8. as Med_Exp_Ded_10Pct,

		/* Medical Expenses Deduction at 7.5% AGI Limit */
		Max(0, TOT_MED_EXP - Max(0,calculated NC_AGI*0.075))
			Format=Bestx8. as Med_Exp_Ded_7p5Pct,


	/* NC 2017-Policy Itemized Deduction Indicator */
		(Case	
			When WS_FLAG_DEDUCT_TYPE = 1 Then 1 Else 2 End)
			FORMAT=1. LABEL="NC 2017-18 Itemized Deduction Indicator" AS NC_2017_ID_IND,

	/* NC 2017 Itemized Deductions w/ 10% AGI Limit Medical Expenses */
		Min(20000,WS_AM_QUAL_MORTG + ABS(WS_AM_REAL_ESTTX)) + WS_AM_CHARIT_CONT + calculated Med_Exp_Ded_10Pct + WS_AM_CLAIMRIGHT
			Format=Bestx9. as NC_ITEM_DED_2017_ME10,

	/* NC 2019-Policy Itemized Deduction Indicator w/ 7.5% AGI Limit Medical Expenses */
		(Case	
			When WS_FLAG_DEDUCT_TYPE = 1 OR (Calculated NC_2019D_SD > Calculated NC_ITEM_DED_2017 > Calculated NC_2017D_SD) Then 1 Else 2 End)
			FORMAT=1. LABEL="NC 2019 Itemized Deduction Indicator" AS NC_2019_ID_IND,

	/* NC 2019-Policy Itemized Deduction Indicator w/ 10% AGI Limit Medical Expenses */
		(Case	
			When WS_FLAG_DEDUCT_TYPE = 1 OR (Calculated NC_2019D_SD > Calculated NC_ITEM_DED_2017_ME10 > Calculated NC_2017D_SD) Then 1 Else 2 End)
			FORMAT=1. LABEL="NC 2019 Itemized Deduction Indicator ME10" AS NC_2019_ID_IND_ME10,

/* NC 2018 Child Deduction */
	/* Estimated number of qualifying children */
			(case	
				When (ws_filing_status in (2,5) and Calculated NC_AGI LE 100000) OR (ws_filing_status in (1,3) and Calculated NC_AGI LE 50000) OR 
					(ws_filing_status = 4 and Calculated NC_AGI LE 80000)
					Then Max(WS_CNT_CHLD_CR,Round(WS_AM_CH_TAX_CR/125,1))
				When ((WS_FILING_STATUS in (1,3) and 75000 > Calculated NC_AGI > 50000) or (WS_FILING_STATUS in (2,5) and 130000 > Calculated NC_AGI >100000) or
					(WS_FILING_STATUS = 4 and 95000 > Calculated NC_AGI > 75000))
					Then Max(0,Ceil(Calculated Tot_Fed_Child_CR/1000))
/*				When (CHILDREN + CHILD_AWAY = 1 and RandU1 < 0.75) Then 1*/
/*				When (CHILDREN + CHILD_AWAY GE 2) Then (Case	*/
/*					When RandU1 LE 0.35 Then (CHILDREN + CHILD_AWAY)*/
/*					When RandU1 LE 0.75 Then Round((CHILDREN + CHILD_AWAY)*0.7,1)*/
/*					When RandU1 LE 0.9 Then Round((CHILDREN + CHILD_AWAY)*0.4,1)*/
/*					Else 0 End)*/
				Else 0 End) FORMAT=2. LABEL="Number of Qualifying Children" AS NC_Qual_Child,

	/* Child Deduction Calculation */
		Calculated NC_Qual_Child * 
		(Case when ((WS_FILING_STATUS in (1,3) and Calculated NC_AGI <= 20000) or 
				(WS_FILING_STATUS in (2,5) and Calculated NC_AGI <= 40000) or
				(WS_FILING_STATUS = 4 and Calculated NC_AGI <= 30000)) Then 2500
			when ((WS_FILING_STATUS in (1,3) and Calculated NC_AGI <= 30000) or 
				(WS_FILING_STATUS in (2,5) and Calculated NC_AGI <= 60000) or
				(WS_FILING_STATUS = 4 and Calculated NC_AGI <= 45000)) Then 2000
			when ((WS_FILING_STATUS in (1,3) and Calculated NC_AGI <= 40000) or 
				(WS_FILING_STATUS in (2,5) and Calculated NC_AGI <= 80000) or
				(WS_FILING_STATUS = 4 and Calculated NC_AGI <= 60000)) Then 1500
			when ((WS_FILING_STATUS in (1,3) and Calculated NC_AGI <= 50000) or 
				(WS_FILING_STATUS in (2,5) and Calculated NC_AGI <= 100000) or
				(WS_FILING_STATUS = 4 and Calculated NC_AGI <= 75000)) Then 1000
			when ((WS_FILING_STATUS in (1,3) and Calculated NC_AGI <= 60000) or 
				(WS_FILING_STATUS in (2,5) and Calculated NC_AGI <= 120000) or
				(WS_FILING_STATUS = 4 and Calculated NC_AGI <= 90000)) Then 500 Else 0 end)
			FORMAT=BESTX5. LABEL="NC 2019 Child Deduction" AS NC_2019D_Child_Ded,

/* NC Credits */
	/* Foreign Credit Calculation */
		WS_AM_TOT_INCOME_FED_TC,
		WS_AM_OUT_OF_STATE_TC,
		WS_AM_TAX_DUE_TC,
		WS_AM_NET_TAX_OUT_ST_TC,
		WS_QT_NBR_STATES_TC,

		WS_AM_FRGN_TAX_CR,
		WS_AM_TAX_CR_C_O,
		WS_AM_LIM_TAX_LIAB_CR,
		/* Consolidate Historic Tax Credits */
		Abs(WS_AM_RHS_INC_PRO) + abs(WS_AM_RHS_NINC_PRO) + Abs(WS_AM_RHMF_INC_PRO) + Abs(WS_AM_RHMF_NINC_PRO) + Abs(WS_AM_HISTINC3L) 
				+ Abs(WS_AM_HISTIN_I3L)
			FORMAT=BESTX8. LABEL="Total Historic Credits" as Hist_Rehab_Credit,
		WS_CNT_CHLD_CR,
		WS_AM_CH_TAX_CR,

	/* Recalculated Non-Limited Credits - 2017 */
		(Abs(WS_AM_FRGN_TAX_CR) + Abs(WS_AM_TAX_CR_C_O) + Calculated Hist_Rehab_credit + ABS(WS_AM_CH_TAX_CR))
			FORMAT=BESTX9. LABEL="Recalculated Credits" as NC_CREDITS_UNLIM_17,

	/* Recalculated Non-Limited Credits - 2019 */
		(Abs(WS_AM_FRGN_TAX_CR) + Abs(WS_AM_TAX_CR_C_O) + Calculated Hist_Rehab_credit) 
			FORMAT=BESTX9. LABEL="Recalculated Credits" as NC_CREDITS_UNLIM_19,

/* 2017 Tax Liability Recalculated from Blurred Components */
	/* Recalculate Taxable Income Before Proration */
		Calculated NC_AGI + Calculated NC_Additions_2017 - Calculated NC_Deductions_2017 - 
			(Calculated NC_ITEM_DED_2017 * ABS(WS_FLAG_DEDUCT_TYPE-1) + Calculated NC_2017D_SD * ABS(WS_FLAG_DEDUCT_TYPE-2))
			Format=Bestx10. As NCTI_Recal_BPro_2017,
	/* Incorporate Proration Factor */
		Calculated NCTI_Recal_BPro_2017  * Calculated ADJ_PRO_PCT
			Format=Bestx10. As NCTI_Recal_APro_2017,
	/* NC Income Tax Calculation */
		Max(0,Calculated NCTI_Recal_APro_2017  * 0.05499)
			Format=Bestx10. As NC_Tax_Calc_2017,
	/* Credits Taken */
		Min(Calculated NC_Tax_Calc_2017, Calculated NC_CREDITS_UNLIM_17 + 
			Max(0,Min(ABS(WS_AM_LIM_TAX_LIAB_CR),Max(0,0.5*(Calculated NC_Tax_Calc_2017 - Calculated NC_CREDITS_UNLIM_17)))))
			Format=Bestx8. As NC_Calc_Credits_Taken_17,
	/* Recalculated NC Net Tax - 2017 Policy */	
		Max(0,Calculated NC_Tax_Calc_2017 - Calculated NC_Calc_Credits_Taken_17)
			Format=Bestx10. As NC_NET_TAX_CALC_17,
	/* Difference High-Level Calculated Net Tax vs. Components Net Tax */
		Calculated NC_NET_TAX_17 - Calculated NC_NET_TAX_CALC_17
			Format=Bestx10. As DIFF_NC_NET_TAX_17_HL_BC,

/* 2017 Tax Liability Recalculated Excluding Medical Expenses Deduction */
	/* Recalculate Taxable Income Before Proration */
		Calculated NC_AGI + Calculated NC_Additions_2017 - Calculated NC_Deductions_2017 - 
			(Calculated NC_ITEM_DED_2017_ExMED * ABS(Calculated NC_2017_ExMED_ID_IND-1) + Calculated NC_2017D_SD * ABS(Calculated NC_2017_ExMED_ID_IND-2))
			Format=Bestx10. As NCTI_Recal_BPro_2017_ExMED,
	/* Incorporate Proration Factor */
		Calculated NCTI_Recal_BPro_2017_ExMED  * Calculated ADJ_PRO_PCT
			Format=Bestx10. As NCTI_Recal_APro_2017_ExMED,
	/* NC Income Tax Calculation */
		Max(0,Calculated NCTI_Recal_APro_2017_ExMED  * 0.05499)
			Format=Bestx10. As NC_Tax_Calc_2017_ExMED,
	/* Credits Taken */
		Min(Calculated NC_Tax_Calc_2017_ExMED, Calculated NC_CREDITS_UNLIM_17 + 
			Max(0,Min(ABS(WS_AM_LIM_TAX_LIAB_CR),Max(0,0.5*(Calculated NC_Tax_Calc_2017_ExMED - Calculated NC_CREDITS_UNLIM_17)))))
			Format=Bestx8. As NC_Calc_Credits_Taken_17_ExMED,
	/* Recalculated NC Net Tax - 2017 Policy */	
		Max(0,Calculated NC_Tax_Calc_2017_ExMED - Calculated NC_Calc_Credits_Taken_17_ExMED)
			Format=Bestx10. As NC_NET_TAX_CALC_17_ExMED,
	/* Estimated Tax Change */
		Calculated NC_NET_TAX_CALC_17_ExMED - Calculated NC_NET_TAX_CALC_17
			Format=Bestx10. As DIFF_Net_Tax_17_ExMED,

/* 2015-Policy Tax Liability  */
	/* Recalculate Taxable Income Before Proration */
		Calculated NC_AGI + Calculated NC_Additions_2017 - Calculated NC_Deductions_2017 - 
			(Calculated NC_ITEM_DED_2015 * ABS(Calculated NC_2015_ID_IND-1) + Calculated NC_2015D_SD * ABS(Calculated NC_2015_ID_IND-2))
			Format=Bestx10. As NCTI_Recal_BPro_2015,
	/* Incorporate Proration Factor */
		Calculated NCTI_Recal_BPro_2015  * Calculated ADJ_PRO_PCT
			Format=Bestx10. As NCTI_Recal_APro_2015,
	/* NC Income Tax Calculation */
		Max(0,Calculated NCTI_Recal_APro_2015  * 0.0575)
			Format=Bestx10. As NC_Tax_Calc_2015,
	/* Credits Taken */
		Min(Calculated NC_Tax_Calc_2015, Calculated NC_CREDITS_UNLIM_17 + 
			Max(0,Min(ABS(WS_AM_LIM_TAX_LIAB_CR),Max(0,0.5*(Calculated NC_Tax_Calc_2015 - Calculated NC_CREDITS_UNLIM_17)))))
			Format=Bestx8. As NC_Calc_Credits_Taken_15,
	/* Recalculated NC Net Tax */	
		Max(0,Calculated NC_Tax_Calc_2015 - Calculated NC_Calc_Credits_Taken_15)
			Format=Bestx10. As NC_NET_TAX_CALC_15,
	/* Estimated Tax Change */
		Calculated NC_NET_TAX_CALC_15 - Calculated NC_NET_TAX_CALC_17
			Format=Bestx10. As DIFF_Net_Tax_15,

	/* Estimated Over/Under-Payment Under 2015  Policy */
		/* Recalculated Over/Under-Payment at 2017 Actual Withholding*/
		Calculated NC_NET_TAX_CALC_15 - WS_AM_TOT_PREPYMT Format=Bestx10. As NC_Tax_Minus_Prepay_15,
		/* Over/Under-Payment Indicator Recalculated Under 2015 Policy*/
		(Case When Calculated NC_Tax_Minus_Prepay_15 > 10 Then 0
			When Calculated NC_Tax_Minus_Prepay_15 < -10 Then 2
			Else 1 End) Format 1. as OverUnder_ind_Calc_15,
		/* Recalculated Over/Under-Payment If No Enhanced Withholding */
		Calculated NC_NET_TAX_CALC_15 - Calculated WS_AM_TOT_PREPYMT_Alt Format=Bestx10. As NC_Tax_Minus_Prepay_Alt_15,
		/* Over/Under-Payment Indicator Recalculated If No Enhanced Withholding*/
		(Case When Calculated NC_Tax_Minus_Prepay_Alt_15 > 10 Then 0
			When Calculated NC_Tax_Minus_Prepay_Alt_15 < -10 Then 2
			Else 1 End) Format 1. as OverUnder_ind_Calc_Alt_15,

/* 2014-Policy Tax Liability  */
	/* Recalculate Taxable Income Before Proration */
		Calculated NC_AGI + Calculated NC_Additions_2017 - Calculated NC_Deductions_2017 - 
			(Calculated NC_ITEM_DED_2014 * ABS(Calculated NC_2014_ID_IND-1) + Calculated NC_2014D_SD * ABS(Calculated NC_2014_ID_IND-2))
			Format=Bestx10. As NCTI_Recal_BPro_2014,
	/* Incorporate Proration Factor */
		Calculated NCTI_Recal_BPro_2014  * Calculated ADJ_PRO_PCT
			Format=Bestx10. As NCTI_Recal_APro_2014,
	/* NC Income Tax Calculation */
		Max(0,Calculated NCTI_Recal_APro_2014  * 0.058)
			Format=Bestx10. As NC_Tax_Calc_2014,
	/* Credits Taken */
		Min(Calculated NC_Tax_Calc_2014, Calculated NC_CREDITS_UNLIM_17 + 
			Max(0,Min(ABS(WS_AM_LIM_TAX_LIAB_CR),Max(0,0.5*(Calculated NC_Tax_Calc_2014 - Calculated NC_CREDITS_UNLIM_17)))))
			Format=Bestx8. As NC_Calc_Credits_Taken_14,
	/* Recalculated NC Net Tax */	
		Max(0,Calculated NC_Tax_Calc_2014 - Calculated NC_Calc_Credits_Taken_14)
			Format=Bestx10. As NC_NET_TAX_CALC_14,
	/* Estimated Tax Change */
		Calculated NC_NET_TAX_CALC_14 - Calculated NC_NET_TAX_CALC_17
			Format=Bestx10. As DIFF_Net_Tax_14,

/* 2019 Tax Liability  */
	/* Recalculate Taxable Income Before Proration */
			Calculated NC_AGI + Calculated NC_Additions_2017 - Calculated NC_Deductions_2017 - 
				(Calculated NC_ITEM_DED_2017 * ABS(Calculated NC_2019_ID_IND - 1) + Calculated NC_2019D_SD * ABS(Calculated NC_2019_ID_IND-2)) - Calculated NC_2019D_Child_Ded
				Format=Bestx10. As NCTI_Recal_BPro_2019,
	/* Incorporate Proration Factor */
			Calculated NCTI_Recal_BPro_2019  * Calculated ADJ_PRO_PCT
				Format=Bestx10. As NCTI_Recal_APro_2019,
	/* NC Income Tax Calculation */
			Max(0,Calculated NCTI_Recal_APro_2019  * 0.0525)
				Format=Bestx10. As NC_Tax_Calc_2019,
	/* Credits Taken */
			Min(Calculated NC_Tax_Calc_2019, Calculated NC_CREDITS_UNLIM_19 + 
				Max(0,Min(ABS(WS_AM_LIM_TAX_LIAB_CR),Max(0,0.5*(Calculated NC_Tax_Calc_2019 - Calculated NC_CREDITS_UNLIM_19)))))
				Format=Bestx8. As NC_Calc_Credits_Taken_19,
	/* Recalculated NC Net Tax - 2019 Policy */	
			Max(0,Calculated NC_Tax_Calc_2019 - Calculated NC_Calc_Credits_Taken_19)
				Format=Bestx10. As NC_NET_TAX_CALC_19,

		RandU1, RandU2, RandU3, RandU4, RandU5, RandU6, RandU7, RandU8, RandU9,
		unmatched, unmatched_IRTF,
		SAMPLE_WEIGHT
	FROM TAXSHRD.NCTAX_TY2017;
	Create Table work.NCTAX_2017_HighAGIChildCredit AS
		Select	*
		FROM NCTAX_2017_Calcs where (((WS_FILING_STATUS in (1,3) and 60000 >= NC_AGI > 50000) or 
				(WS_FILING_STATUS in (2,5) and 120000 >= NC_AGI >100000) or
				(WS_FILING_STATUS = 4 and 90000 >= NC_AGI > 75000)) and Tot_Fed_Child_CR > 1) order by Tot_Fed_Child_CR;
	Create Table work.NCTAX_2017_IRTF_Unmatched AS
		Select	*
		FROM NCTAX_2017_Calcs where (unmatched_IRTF<>unmatched) and (ws_residency_status in (1,2));
Quit;
