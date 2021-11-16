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
    header='infer'
)

########################################
#Clean
########################################

# 1. Make long, not wide, for ease

val_vars = [str(i) for i in range(2015, 2051)]

inc = pd.melt(
    df,
    id_vars=["category", "subcategory1", "subcategory2", "unit"],
    value_vars=val_vars,
    var_name="year",
    value_name="number",
)

# 2. Rename

rename = {'Unemployment Rate, Civilian, 16 Years or Older':'unemp_rate', 'Labor Force, Civilian, 16 Years or Older': 'laborforce', Labor Force Participation Rate, 16 Years or Older: lfp_rate, Employment, Civilian, 16 Years or Older (Household Survey):'emp', 'Employment, Total Nonfarm (Establishment Survey)': 'nonfarm_emp', 'Noninstitutional Population, Civilian, 16 Years or Older', 'pop', 'Households (Total Occupied Housing Units)':'hhs', 'Income, Personal', 'personal_inc', 'Wages and Salaries':wages, 'Nonwage Income', 'total_nonwage', }


########################################
# Make Incomes Per Capita 
########################################
# 1. Make millions in to billions

inc.loc[inc.unit=='Millions', 'number'] = inc.number*.001
inc.replace('Millions', 'billions', inplace=True)




# 2. Per Capita

inc["income_percap"] = np.nan

###### Unpivot Labor category to put in column next to 
inc = inc.pivot(index=['year', 'unit'], columns=['category', 'subcategory1', 'subcategory2', ], values='number').reset_index()

inc.columns = map(
        lambda x: str(x[0]) + "_" + str(x[1]), inc.columns
    )  # Collapse level

    off2.columns = off2.columns.str.lstrip(
        "_"
    )  # strip leading "_" that was put on some columns in step above

    # 7. Indicate Part 1




















(
    inc.dollars / inc.employment
)  # dollars per worker, to account for pop. growth

inc.sort_values(["comp", "subcomp", "year"], inplace=True, ascending=[True, True, True])

# 2. Pct Change
inc["pct_change"] = np.nan

inc["pct_change"] = inc.groupby(["comp", "subcomp"])[
    "dollars_per_wkr"
].pct_change()  # calc percent change by income group

assert inc[inc.year == inc.year.min()]["pct_change"].isna().all()  # check

########################################
# Final Cleaning/Subsetting
########################################

inc_all = inc  # save full version before subsetting

# 1. Rename things
inc_dict = {
    "Income, Personal": "tot_personal",
    "Dividend income, personal": "div",
    "Income, rental, with CCAdj": "rent",
    "Interest income, personal": "int",
    "Nonwage Income": "tot_nonwage",
    "Proprietors' income, farm, with IVA & CCAdj": "farm_prop",
    "Proprietors' income, nonfarm, with IVA & CCAdj": "nonfarm_prop",
    "Wages and Salaries": "wage",
}

inc.replace(inc_dict, inplace=True)
inc.rename(columns={"subcomp": "income_source"}, inplace=True)

# 2. Redefine with just variables we need
# Excludes 'Compensation of Employees, Paid', 'Profits, Corporate, Domestic, With IVA & CCAdj', and 'Profits, Corporate, With IVA & CCAdj'

inc = inc[
    (inc.comp == "wage") | (inc.comp == "tot_nonwage") | (inc.comp == "tot_personal")
]


# 3. Convert back to wide

inc = inc.pivot_table(columns=["year", "income_source"], values=["pct_change"])

######3a. Compress multiindex

inc.columns = ["_".join(col).strip() for col in inc.columns.values]
inc

########################################
# Exports
#########################################

inc_all.to_csv(
    "/Users/samsloate/Desktop/807 MP/masters_project/data/cbo/short_term_economic_projections_clean_all.csv",
    index=False,
)
inc.to_csv(
    "/Users/samsloate/Desktop/807 MP/masters_project/data/cbo/short_term_economic_projections_clean_subset.csv",
    index=False,
)
