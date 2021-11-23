import pandas as pd
import numpy as np
import janitor

%load_ext nb_black


########################################
# Imports: Short Term
########################################
df = pd.read_csv(
    "https://raw.githubusercontent.com/ssloate/masters_project/main/data/cbo/all_economic_projections_clean.csv",
    encoding="latin-1",
    skiprows=7,
    sep=",",
    header="infer",
)
df.drop(columns={"subcategory1"}, inplace=True)  # drop repetitive column

########################################
# Clean
########################################

# 1. Make long, not wide, for ease

val_vars = [str(i) for i in range(2015, 2051)]

inc = pd.melt(
    df,
    id_vars=["category", "subcategory2", "unit"],
    value_vars=val_vars,
    var_name="year",
    value_name="number",
)

# 2. Rename

rename = {
    "Unemployment Rate, Civilian, 16 Years or Older": "unemp_rate",
    "Nonwage Income": "nonwage_inc",
    "Profits, Corporate, Domestic, With IVA & CCAdj": "dom_corp_profit",
    "Profits, Corporate, With IVA & CCAdj": "corp_profit",
    "Dividend income, personal": "div_inc",
    "Interest income, personal": "int_inc",
    "Income, rental, with CCAdj": "rent_inc",
    "Proprietors' income, nonfarm, with IVA & CCAdj": "nonfarm_prop_inc",
    "Proprietors' income, farm, with IVA & CCAdj": "farm_prop_inc",
    "Wages and Salaries": "wages",
    "Labor Force, Civilian, 16 Years or Older": "laborforce",
    "Compensation of Employees, Paid": "emp_comp",
    "Income, Personal": "personal_inc",
    "Noninstitutional Population, Civilian, 16 Years or Older": "population",
    "Employment, Total Nonfarm (Establishment Survey)": "tot_nonfarm_emp",
    "Employment, Civilian, 16 Years or Older (Household Survey)": "total_emp",
    "Labor Force Participation Rate, 16 Years or Older": "lfp_rate",
    "Growth of Real Earnings Per Worker": "real_earn_per_wkr_growth",
}

inc.subcategory2.replace(rename, inplace=True)

########################################
# Make Incomes Per Capita
########################################

# 1. Make millions in to billions

inc.loc[inc.unit == "Millions", "number"] = inc.number * 0.001
inc.replace("Millions", "billions", inplace=True)

# 2. Pivot
inc = inc.pivot(
    index=["year"], columns="subcategory2", values="number"
).reset_index()

# 2. Per Capita, by income type

inc["wage_inc_pc"] = inc.wages / inc.total_emp
inc["bus_inc_pc"] = inc.nonfarm_prop_inc / inc.tot_nonfarm_emp
inc["farm_inc_pc"] = inc.farm_prop_inc / (inc.total_emp-inc.tot_nonfarm_emp)
inc["pers_inc_pc"] = inc.personal_inc / inc.population
inc["int_inc_pc"] = inc.int_inc / inc.population
inc["unemp_inc_pc"] = inc.wages / (inc.unemp_rate * inc.laborforce)
inc["div_inc_pc"] = inc.div_inc / inc.population
inc["rent_inc_pc"] = inc.rent_inc / inc.population


########################################
# Calculate Percent Change
########################################

for col in inc.columns[inc.columns.str.contains('pc')]:
    inc[f'{col}_rate'] = inc[col].pct_change()

# Make Real Earnings Per Worker growth in %
inc.real_earn_per_wkr_growth = inc.real_earn_per_wkr_growth / 100

########################################
# Final Cleaning/Subsetting
########################################

inc_all = inc  # save full version before subsetting

# 1. Subset to just variables we need

inc_subset= inc[['year', 'wage_inc_pc_rate', 'bus_inc_pc_rate', 'farm_inc_pc_rate', 'pers_inc_pc_rate', 'int_inc_pc_rate', 'unemp_inc_pc_rate', 'div_inc_pc_rate', 'rent_inc_pc_rate', 'real_earn_per_wkr_growth']]


# 2. Convert back to wide

inc_subset['index'] = 'index'

inc_subset = inc_subset.pivot_table(index='index', columns=['year'], values=['wage_inc_pc_rate', 'bus_inc_pc_rate', 'farm_inc_pc_rate', 'pers_inc_pc_rate', 'int_inc_pc_rate', 'unemp_inc_pc_rate', 'div_inc_pc_rate', 'rent_inc_pc_rate', 'real_earn_per_wkr_growth', ]).reset_index()

# 3. Rename columns
inc_subset.columns = map(
        lambda x: str(x[1]) + "_" + str(x[0]), inc_subset.columns
    )  # Collapse level

inc_subset.columns = inc_subset.columns.str.lstrip(
        "_"
    )  # strip leading "_" that was put on some columns in step above

# 4. Replace 0s with Nan in long-term years
for col in inc_subset.columns[18:]:
    inc_subset[col].replace(0, np.nan, inplace=True)


#5. Rename category
inc_subset.rename(columns={'subcategory2':'growth_rate'}, inplace=True)
inc_subset.drop('index', axis=1, inplace=True)

########################################
# Exports
#########################################

inc_subset.to_csv(
    "/Users/samsloate/Desktop/807 MP/masters_project/data/cbo/all_economic_growth_rates_clean.csv",
    index=False,
)
