import pandas as pd
import numpy as np
import janitor

%load_ext nb_black

path = "/Users/samsloate/Desktop/807 MP/masters_project/data/cps/"


########################################
# Import and Subset Raw CPS 
########################################

## Raw CPS is stored on Sam's computer. It is too big for GitHub.
cps = pd.read_csv(path + "raw_cps_microdata.csv")

# Subset for NC and 2015-2019
cps = cps[(cps.STATEFIP==37) & (cps.YEAR<=2019)]  
cps = cps.clean_names()


########################################
# Rename Variables 
########################################


# 1. recode race

race_dict = {
    100: "white",
    200: "black",
    300: "aian",
    650: "aapi",
    651: "aapi",
    652: "aapi",
    700: "other",
    801: 'multi',
    802: 'multi',
    803: 'multi',
    804: 'multi',
    805: 'multi',
    806: 'multi',
    807: 'multi',
    808: 'multi',
    809: 'multi',
    810: 'multi',
    811: 'multi',
    812: 'multi',
    813: 'multi',
    814: 'multi',
    815: 'multi',
    816: 'multi',
    817: 'multi',
    818: 'multi',
    819: 'multi',
    820: 'multi',
    830: 'multi',
    999: np.nan
}

cps.replace({"race": race_dict}, inplace=True)

# 2. recode sex

cps.sex.replace({1: "m", 2: "f"}, inplace=True)

# 3. recode Hispanic

cps.loc[(cps.hispan>0)&(cps.hispan<901), 'hispan'] = 'hisp'
cps.loc[(cps.hispan=="901") | (cps.hispan=="902"), 'hispan'] = np.nan
cps.hispan.replace({0: "nonhisp"}, inplace=True)

# 4. recode marital status

marst_dict = {
    1: "married",
    2: "married",
    3: "not married",
    4: "not married",
    5: "not married",
    6: "not married",
    9: np.nan

}

cps.replace({"marst": marst_dict}, inplace=True)


# 5. recode filing status

filestat_dict = {
    0: np.nan,
    1: "joint_under65",
    2: "joint_mixed65",
    3: "joint_over65",
    4: "hh_head",
    5: "single",
    6: "nonfiler",
}

cps.replace({"filestat": filestat_dict}, inplace=True)


# 6. Other cleaning
cps.drop("unnamed_0", axis=1, inplace=True)

########################################
# Export
########################################

# Export clean, non-edited CPS
cps.to_csv(path + "clean_cps_microdata.csv")
