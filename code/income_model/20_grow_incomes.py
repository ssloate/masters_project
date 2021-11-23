import pandas as pd
import numpy as np
import janitor

%load_ext nb_black


########################################
# Imports
########################################


inc = pd.read_csv(
    "https://raw.githubusercontent.com/ssloate/masters_project/main/data/cbo/all_economic_growth_rates_clean.csv",
    encoding="latin-1",
    sep=",",
)

cps = pd.read_csv('https://raw.githubusercontent.com/ssloate/masters_project/main/data/cps/clean_cps_microdata.csv')


##################################################
# Merge Inc Growth and CPS datasets
##################################################

# 1. Extend inc dataset
inc = pd.concat([inc]*len(cps), ignore_index=True)

# 2. Merge inc and cps
cps = cps.join(inc)


########################################
# Replace NaNs
########################################

#1. Replace 999999s with NaNs

to_replace_8 = [
    "oincwage",
    "oincbus",
    "oincfarm",
    "incretir",
    "inclongj"
]  # 99999999 indicates missing
to_replace_7 = [
    "incint",
    "incvet",
    "incsurv",
    "incdisab",
    "incdivid",
    "incrent",
    "incasist",
    "incother",
]  # 9999999 indicates missing
to_replace_6 = [
    "incss",
    "incwelfr",
    "incssi",
    "incunemp",
    "incwkcom",
    "inceduc",
    "incchild",
]  # 999999 indicates missing

for i in to_replace_8:
    cps[i].replace(99999999, np.nan, inplace=True)

for i in to_replace_7:
    cps[i].replace(9999999, np.nan, inplace=True)

for i in to_replace_6:
    cps[i].replace(999999, np.nan, inplace=True)

########################################
# Input topcoded incomes
########################################

#SCREARN
#0	NIU
#1	Wage and salary
#2	Self employment
#3	Farm self employment
#4	Without pay

# 1. Fix topcoded incomes for farm, business, and wage
cps.loc[cps.oincwage == 9999999, 'oincwage_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE]
cps.loc[cps.oincbus == 9999999, 'oincbus_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE]
cps.loc[cps.oincfarm == 999999, 'oincfarm_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE]

# 2. Fix topcoded incomes for inclongj
cps.loc[(cps.inclongj == 9999999) & (cps.screarn==1), 'inclongj_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] #wage
cps.loc[(cps.inclongj == 9999999) & (cps.screarn==2), 'inclongj_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] #business
cps.loc[(cps.inclongj == 9999999) & (cps.screarn==3), 'inclongj_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] #farm


#3. Fix topcoded incomes for the rest

#### 2015-2018 topcodes
cps.loc[(cps.incretir == 99999) & (cps.year<2019), 'incretir_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # retirement
cps.loc[(cps.incint == 99999) & (cps.year<2019), 'incint_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # interest
cps.loc[(cps.incunemp == 99999) & (cps.year<2019), 'incunemp_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # unemployment
cps.loc[(cps.incdiv == 999999) & (cps.year<2019), 'incdiv_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # dividend
cps.loc[(cps.incrent== 99999) & (cps.year<2019), 'incrent_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # rental

#### 2019 topcodes
cps.loc[(cps.incretir == 999999) & (cps.year==2019), 'incretir_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # retirement
cps.loc[(cps.incint == 999999) & (cps.year==2019), 'incint_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # interest
cps.loc[(cps.incunemp == 99999) & (cps.year==2019), 'incunemp_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # unemployment
cps.loc[(cps.incdiv == 999999) & (cps.year==2019), 'incdiv_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # dividend
cps.loc[(cps.incrent== 999999) & (cps.year<2019), 'incrent_adj'] = [FILL IN MEDIAN VALUE FROM ED HERE] # rental


##################################################
# Compute non-top-coded wage/farm/business income
##################################################

##### Compute wage income
cps['incwage_adj'] = np.nan
cps.loc[cps.screarn==1, 'incwage'] = cps.inclongj_adj + cps.oincwage_adj

##### Compute business income
cps['incbus_adj'] = np.nan
cps.loc[cps.screarn==2, 'incbus'] = cps.inclongj_adj + cps.oincbus_adj

##### Compute farm income
cps['incfarm_adj'] = np.nan
cps.loc[cps.screarn==3, 'incfarm'] = cps.inclongj_adj + cps.oincfarm_adj

##################################################
# Grow 2015-2018 incomes up to 2019
##################################################

for i in ['wage', 'bus', 'farm', 'div', 'int', 'rent', 'unemp']:
    # 2015
    cps.loc[cps.year==2015, f'2019_inc{i}'] = ((1+ cps[f'2016_{i}_inc_pc_rate']) * cps[f'inc{i}_adj']) * (1+ cps[f'2017_{i}_inc_pc_rate']) * (1+ cps[f'2018_{i}_inc_pc_rate']) * (1+ cps[f'2019_{i}_inc_pc_rate']) # 2019 growth rate takes 2016, 2017, 2018, and 2019 growth rates in to account, adding them on to the base incwage_adj

    #2016
     cps.loc[cps.year==2016, f'2019_inc{i}'] = ((1+ cps[f'2017_{i}_inc_pc_rate']) * cps[f'inc{i}_adj']) * (1+ cps[f'2018_{i}_inc_pc_rate']) * (1+ cps[f'2019_{i}_inc_pc_rate'])

    #2017
    cps.loc[cps.year==2017, f'2019_inc{i}'] = ((1+ cps[f'2018_{i}_inc_pc_rate']) * cps[f'inc{i}_adj']) * (1+ cps[f'2019_{i}_inc_pc_rate'])

    #2018
    cps.loc[cps.year==2018, f'2019_inc{i}'] = ((1+ cps[f'2019_{i}_inc_pc_rate']) * cps[f'inc{i}_adj'])


for i in ['retir']:
    #2015
     cps.loc[cps.year==2015, f'2019_inc{i}'] = ((1+ cps[f'2016_{i}_inc_pc_rate']) * cps[f'inc{i}_adj']) * (1+ cps[f'2017_{i}_inc_pc_rate']) * (1+ cps[f'2018_{i}_inc_pc_rate']) * (1+ cps[f'2019_{i}_inc_pc_rate'])

    #2016
    cps.loc[cps.year==2016, f'2019_inc{i}'] = ((1+ cps[f'2017_{i}_inc_pc_rate']) * cps[f'inc{i}_adj']) * (1+ cps[f'2018_{i}_inc_pc_rate']) * (1+ cps[f'2019_{i}_inc_pc_rate'])

    #2017
    cps.loc[cps.year==2017, f'2019_inc{i}'] = ((1+ cps[f'2018_{i}_inc_pc_rate']) * cps[f'inc{i}_adj']) * (1+ cps[f'2019_{i}_inc_pc_rate'])

    #2018
    cps.loc[cps.year==2018, f'2019_inc{i}'] = ((1+ cps[f'2019_{i}_inc_pc_rate']) * cps[f'inc{i}_adj'])

##################################################
# Grow 2019
##################################################
