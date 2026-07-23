# prepare_for_bson.jl

"""
    prepare_for_bson(df)
    
Convert problematic column types to BSON-compatible formats.
Handles all InlineStrings variants and other problematic types.
"""
function prepare_for_bson(df::AbstractDataFrame)
    df_copy = copy(df)
    
    for col in names(df_copy)
        col_type = eltype(df_copy[!, col])
        type_str = string(col_type)
        
        # Case 1: Direct InlineStrings
        if occursin("InlineStrings", type_str)
            if occursin("CategoricalValue", type_str)
                # Handle categorical columns with InlineStrings
                df_copy[!, col] = categorical(passmissing(String).(df_copy[!, col]))
            else
                # Handle regular InlineStrings columns
                df_copy[!, col] = passmissing(String).(df_copy[!, col])
            end
        
        # Case 2: Any type - check and convert each element
        elseif col_type == Any
            # Process each cell individually
            for i in 1:nrow(df_copy)
                val = df_copy[i, col]
                
                # Skip missing values
                if ismissing(val)
                    continue
                end
                
                # Check if the value contains InlineStrings
                if typeof(val) <: CSV.InlineStrings.InlineString
                    df_copy[i, col] = String(val)
                elseif val isa Vector && !isempty(val) && eltype(val) <: CSV.InlineStrings.InlineString
                    df_copy[i, col] = String.(val)
                end
            end
        
        # Case 3: Union{Missing, Nothing, Int64} - normalize Nothing to missing
        elseif Union{Missing, Nothing, Int64} == col_type
            # Convert Nothing to missing for consistency
            df_copy[!, col] = [v === nothing ? missing : v for v in df_copy[!, col]]
        end
    end
    
    return df_copy
end
