# variables.jl

global kin = :kin431;
global socio = :socio4;

export kin, socio

global rates = [:tpr, :fpr];
export rates

global rls = (ft = "free_time", pp = "personal_private",);
export rls

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
ppth = (
    b = "honduras-css-paper/",
    t = "tables/", f = "figures/",
    st = "tables_si/", sf = "figures_si/",
);

export ppth
