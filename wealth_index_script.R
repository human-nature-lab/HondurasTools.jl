# SCRIPT TO CALCULATE WEALTH INDEX FOR HONDURAS RCT
# modified: 2020-10-07 by Selena Lee
# modified further: 2023-09-25 by Eric Feltham

# this version
# (1) calculates both quintized and non-binned indices
# (2) weighted and unweighted quintized measures (they are almost identical)
# (3) loops over waves 1 and 3 to produce a combined CSV file

# added #WAVE SPECIFIC tag following lines where adjustment needs to be
# made between waves

# TODO (emf) check whether the calculation actually changes across waves?

# Notes from Selena:
# This wealth index DOES NOT include the handwashing variables (l0500, l0600), as the variation in these variables
# seems to be captured by water source (l0400) and toilet type (l0700, l0800) variables. When using different
# combinations of handwashing, water source, and toilet type variables, the first dimension of the MCA flips
# depending on whatt grouping of these variables is used. This indicates that a certain mix of these variables
# is overcorrelated when used altogether (namely, I found the handwashing variables in conjuction with the water
# source variables to be overcorrelated, flipping the model). Hence, I use only the water source and toilet type
# variables in the wealth index generation below.

# Wealth index generation guidelines:
# https://dhsprogram.com/programming/wealth%20index/Steps_to_constructing_the_new_DHS_Wealth_Index.pdf

# library(dummies)
library(zoo)
library(tidyverse)
library(DescTools)
library(mltools)
# library(factoextra) # PCA/MCA visualization
library(reshape2)

library(FactoMineR) # for running MCA (PCA for predominantly categorical data)
# library(missMDA) # for handling missing values in MCA


#### Loadings ####

# ignore wave 2

# Specify path for saving csv files
hhpaths <- c(
    "WAVE1/v8_2021-03/honduras_households_WAVE1_v8.csv",
    # "WAVE2/v5_2021-03/honduras_households_WAVE2_v5.csv",
    "WAVE3/v3_2021-03/honduras_households_WAVE3_v3.csv"
)

# no calculable wave 4 index
resppaths <- c(
    "WAVE1/v8_2021-03/honduras_respondents_WAVE1_v8.csv",
    # "WAVE2/v5_2021-03/honduras_respondents_WAVE2_v5.csv",
    "WAVE3/v3_2021-03/honduras_respondents_WAVE3_v3.csv"
)

mca_out <- list()
wealth_df <- tibble()

is <- c(1, 3)

for (i in seq_along(hhpaths)) {
    resp1 <- read_csv(paste0("../", resppaths[i]))
    hh1 <- read_csv(paste0("../", hhpaths[i]))

    v1 <- paste0("building_id_", "w", is[i])
    v2 <- paste0("village_code_", "w", is[i])
    v3 <- paste0("data_source_", "w", is[i])

    resp1 <- rename(
        resp1,
        building_id = !!v1,
        village_code = !!v2,
        data_source = !!v3
    )

    # hh1 <- rename(
    #     hh1,
    #     # building_id = !!v1,
    #     # village_code = !!v2,
    # )

    ##### Multiple correspondence analysis ######

    resp <- resp1 %>%
    filter(village_code != 0 & data_source != 3)

    # Include income sufficiency from respondents data set to layer over/color
    # MCA plot of individuals (to visually validate MCA-generated wealth
    # index). Count the number of respondents per building and merge the
    # building count with the household survey data. Add the number of children
    # to the number from the respondents table to get the total housheold size
    # (thhsize) for all households surveyed. Compute people in the household
    # per room to be included as a supplementary variable in the MCA analysis
    # below. Recode household variables to deal with NA's.
    hh <- hh1 %>%
    filter(village_code != 0 & !is.na(respondent_master_id))

    resp2 <- resp %>%
        mutate(
            d0700.binary = recode(
                d0700,
                `It is not sufficient and there are major difficulties` = 0,
                `It is not sufficient and there are difficulties` = 0,
                `It is sufficient, without major difficulties` = 1,
                `There is enough to live on and save` = 1
            ),
            d0700.full = recode(
                d0700,
                `It is not sufficient and there are major difficulties` = 0,
                `It is not sufficient and there are difficulties` = 1,
                `It is sufficient, without major difficulties` = 2,
                `There is enough to live on and save` = 3
            )
        ) %>%
        group_by(building_id) %>%
        summarise(
            bldgsize = length(respondent_master_id), #WAVE SPECIFIC
            incomesufficiency.binary = round(mean(d0700.binary, na.rm = TRUE)),
            incomesufficiency.full = round(mean(d0700.full, na.rm = TRUE))) %>%
        mutate(
            incomesufficiency.categorical = recode(
                incomesufficiency.full,
                `0` = "It is not sufficient and there are major difficulties",
                `1` = "It is not sufficient and there are difficulties",
                `2` = "It is sufficient, without major difficulties",
                `3` = "There is enough to live on and save"
            )
        )

    hh <- left_join(hh, resp2) %>%
    mutate(
        children = na.aggregate(
            ifelse(
                !is.na(l0100), as.numeric(as.character(l0100)),
                as.numeric(as.character(l0200)) +
                as.numeric(as.character(l0300))
            ),
            village_code
        ),
        thhsize = na.aggregate(bldgsize+children, village_code),
        rooms = na.aggregate(
            as.numeric(as.character(l1700)), village_code
        ),
        peopleperroom = na.aggregate(
            thhsize / as.numeric(as.character(rooms)), village_code
        ),
        l1400 = gsub("\\.", "", l1400), #some data cleaning
        l1400 = gsub("There aren't windows", "There_arent_windows", l1400),
        # Recode to match question skip in survey (selecting handwashing
        # station is "Not observed", as in there is no handwashing sation, for
        # l0500 skips l0600; selecting "No facility (outdoors)" for l0700 skips
        # question l0800).
        # Create new responses for l0600 to parallel l0500 responses.
        # Create new responses for l0700 indicating whether the toilet type is
        # shared (this combines l0700 and l0800 into just l0700).
        l0600 = ifelse(
            l0500 == "Not observed", "Not observed", as.character(l0600)
        ),
        l0700 = ifelse(
            is.na(l0800) | l0800 == "No",
            as.character(l0700),
            paste(as.character(l0700), "shared", sep = " ")
        ),
        # Recode NA's for the l0900 variables as absence of feature/item.
        l0900a = ifelse(is.na(l0900a), "No electricty", as.character(l0900a)),
        l0900b = ifelse(is.na(l0900b), "No radio", as.character(l0900b)),
        l0900c = ifelse(
            is.na(l0900c), "No television", as.character(l0900c)
        ),
        l0900d = ifelse(
            is.na(l0900d), "No cell/mobile phone", as.character(l0900d)
        ),
        l0900e = ifelse(
            is.na(l0900e), "No non-mobile phone", as.character(l0900e)
        ), #WAVE SPECIFIC may include l0900f
        l0900g = ifelse(
            is.na(l0900g),
            "At least one feature/item present",
            as.character(l0900g))
        ) %>%
        # Subset as listwise deletion for "Dont_Know" values in all variables
        # (the individual with all NA's was
        # dropped due to the subset function preloadings).
        subset(
            l0400 != "Dont_Know" & l1000 != "Dont_Know" &
            l1100 != "Dont_Know" & l1200 != "Dont_Know" & l1600 != "Dont_Know"
        )

    # Check: when all l0900 vars are no, l0900g is also no (this should match
    # up). Yes, this matches up. hh[hh$l0900a == "No electricity" & hh$l0900b
    # == "No radio" & hh$l0900c == "No television" & hh$l0900d ==
    # "No cell/mobile phone" & hh$l0900e == "No non-mobile phone" &
    # hh$l0900g == "At least one feature/item present",]

    # Select variables for MCA and remove extraneous ones
    hh_for_mca <- hh %>%
    dplyr::select(
        l0400:l1600,
        -c(l0500, l0600, l0800, l0900),
        incomesufficiency.binary, peopleperroom
    )

    # Run MCA with peopleperroom as quantitative supplementary variable and
    # incomesufficiency as qualitative supplementary variable (supplementary
    # variables are not included in analysis). It seems fine to exclude
    # peopleperroom from the actual analysis, since the variable peopleperroom
    # is perfectly aligned in the negative direction of the first dimension
    # (lower wealth householeds), meaning more people per sleeping room is 
    # correlatted with a poorer household as would be expected. Likewise, other
    # variables contribute more significantly to the analysis than
    # peopleperroom would (see summary of MCA output), so the peopleperroom
    # variation seems to already be explained in the analysis.
    # Incomesufficiency is for quick visual validation of the MCA-generated
    # wealth index
    wealth.mca <- MCA(hh_for_mca, quanti.sup = 17, quali.sup = 16, ncp = 3)
    # WAVE SPECIFIC
    # summary(wealth.mca)

    #### Generate wealth index ####
    indiv.mca <- wealth.mca$ind

    # Generate an unweighted, individual wealth index for each household
    # respondent. Quintiles are labeled using the Dimension 1 coordinates,
    # as the wealthier households/individuals are located on the positive end
    # of Dimension 1. See commented out figure below for verification:
    # Visualize income insufficiency (binarized)
    # pv1 <- factoextra::fviz_mca_ind(
    #     wealth.mca,
    #     axes = c(1, 2),
    #     label = "none", # hide individual labels
    #     habillage = 16, # 18, # color by groups (sufficient or insufficient
    #     income)
    #     palette = c("#00AFBB", "#E7B800", "#FC4E07"),
    #     addEllipses = TRUE
    # ) + # Concentration ellipses
    #     theme_classic()

    # ggsave("old_vis.png", pv1)

    index_data <- hh %>%
    select(building_id, thhsize) %>%
    cbind(indiv.mca$coord[, 1]) %>%
    rename(wealth.mca_dim1_coord = `indiv.mca$coord[, 1]`) %>%
    tibble()

    index_data <- index_data %>%
    mutate(
            wealthindex_indiv = cut(
                wealth.mca_dim1_coord,
                breaks = quantile(wealth.mca_dim1_coord, probs = seq(0, 1, 0.2)),
                include.lowest = TRUE, labels = 1:5
            )
        )

    # Generate weighted, household wealth index quintiles. Weight the index
    # coordinates by duplicating for each household member. Quintiles are
    # labeled using the Dimension 1 coordinates; the wealthier households/
    # individuals are
    # located on the positive end of Dimension 1.
    index_data_expanded <- index_data[
        rep(row.names(index_data), index_data$thhsize),
    ]

    index_data_expanded$wealthindex_hh <- cut(
        index_data_expanded$wealth.mca_dim1_coord,
        breaks = quantile(
            index_data_expanded$wealth.mca_dim1_coord,
            probs = seq(0, 1, 0.2)
        ),
        include.lowest = TRUE,
        labels = 1:5
    )


    household_wealth <- index_data_expanded %>%
        select(building_id, wealthindex_hh) %>%
        distinct(building_id, .keep_all = T) %>%
        left_join(index_data)

    # cor(
    #     as.numeric(household_wealth$wealthindex_hh),
    #     as.numeric(household_wealth$wealthindex_indiv)
    # )

    household_wealth <- rename(
        household_wealth,
        hh_wealth_index = wealth.mca_dim1_coord,
        hh_wealth_index_5 = wealthindex_indiv,
        hh_wealth_index_5_wgt = wealthindex_hh,
    )

    # p1 <- household_wealth %>% ggplot(aes(hh_wealth_index)) +
    #   geom_histogram(aes(y = after_stat(density))) + theme_classic()
    # ggsave("test3.png", p1)

    # Aggregate index by village to create village wealth index.
    # village_wealth <- hh %>%
    #   select(village_code, building_id) %>%
    #   left_join(household_wealth) %>%
    #   group_by(village_code) %>%
    #   summarise(
    #     village_wealth_index = mean(
    #         as.numeric(as.character(wealthindex_hh)), na.rm = T
    #     ),
    #     village_wealth_index_median = median(
    #         as.numeric(as.character(wealthindex_hh)), na.rm = T)
    #     )

    household_wealth$wave <- is[i]
    wealth_df <- rbind(wealth_df, household_wealth)

    mca_out[is[i]] <- wealth.mca
}
##### Save files #####

# Write the modified household data set to a csv file 
#write.csv(hh, "hw1_household_2020-09-03.csv"), row.names = F)

# Save MCA output as R object
save(
    mca_out,
    file = paste0("mca_output_", today(), ".rda")
)

# Write the household wealth index to a csv file.
write_csv(wealth_df, file = paste0("hh_wealth_", today(), ".csv"))

# Write the village wealth index to a csv file 
# write.csv(
#     village_wealth,  "hw1_village_wealth_2020-10-30.csv", row.names = F
# )
