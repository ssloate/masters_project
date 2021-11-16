import pandas as pd
import numpy as np
import janitor

%load_ext nb_black


########################################
# Imports
########################################


inc = pd.read_csv(
    "https://raw.githubusercontent.com/ssloate/masters_project/main/data/cbo/all_economic_projections_clean.csv",
    encoding="latin-1",
    skiprows=7,
    sep=",",
    header='infer'
)

cps = pd.read_csv('https://raw.githubusercontent.com/ssloate/masters_project/main/data/cps/clean_cps_microdata.csv')

########################################
# Clean CPS 
########################################

#1. Replace 999999s with NaNs

to_replace_8 = [
    "incwage",
    "incbus",
    "incfarm",
    "incretir",
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

    
# stretch out Income dataset
inc = inc.append(
    [inc] * (len(cps) - 1), ignore_index=True
)  # makes the one-row dataset as long as the cps dataset


########################################
# Merge CBO Income and CPS Datasets 
########################################

# add inc dataset to cps data set
cps_inc = cps.join(inc)

