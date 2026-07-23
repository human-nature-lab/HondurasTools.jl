# household_pairs.jl

"""
Add building ID information for alter1 and alter2 in a network DataFrame.

This function:
1. Joins respondent building IDs to both alter1 and alter2 columns
2. Creates a same_building indicator variable

Parameters:
- df: DataFrame containing alter1 and alter2 columns
- respondent_df: DataFrame containing name and building_id columns
- return_df: Bool, if true returns the modified DataFrame (default: false)

Returns:
- The modified DataFrame if return_df is true, otherwise nothing
"""
function add_building_info!(df, respondent_df; return_df=false)
    # Define column names for clarity
    bd = :building_id
    a1 = :building_id_a1
    a2 = :building_id_a2
    
    # Create a reduced respondent DataFrame with just name and building_id
    respondent_reduced = select(respondent_df, [:name, bd])
    respondent_reduced = unique(respondent_reduced)
    
    # Join building IDs for alter1
    rename!(respondent_reduced, bd => a1)
    leftjoin!(df, respondent_reduced, on = :alter1 => :name)
    
    # Join building IDs for alter2
    rename!(respondent_reduced, a1 => a2)
    leftjoin!(df, respondent_reduced, on = :alter2 => :name)
    
    # Create indicator for same building
    df[!, :same_building] = df[!, a1] .== df[!, a2]
    
    return return_df ? df : nothing
end
