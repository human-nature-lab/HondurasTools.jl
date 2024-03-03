# variables.jl

kin = :kin431;
socio = :socio4;

export kin, socio

# useful variables
rates = [:tpr, :fpr];
export rates

# Reports paths
prj = (
    pp = "./honduras-reports/",
    dev = "development/",
    ind = "indigeneity/",
    cop = "cooperation/",
    rel = "religion/",
    net = "network/",
    css = "CSS/",
    int = "intervention/",
    apx = "appendix/"
)

export prj

# Paper paths
ppath = (b = "css-paper/", t = "tables/", f = "figures/");

export ppath
