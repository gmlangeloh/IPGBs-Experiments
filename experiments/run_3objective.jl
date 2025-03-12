"""
Reproduces experiments from Jimenez-Tafur's thesis.
"""

import Random
using Logging

using IPGBs
using MultiObjectiveInstances
using MultiObjectiveInstances.Knapsack

using DataFrames
using CSV

function printheader()
    println("family seed n m bin pareto t12 t21 ips totaltime timet12 timet21 timegb timenf timesolver")
end

function runsolve(
    family :: String,
    n :: Int,
    p :: Int,
    repetitions :: Int,
    binary :: Bool
)
    m = 1
    if family == "A"
        generator = knapsack_A
    elseif family == "C"
        generator = knapsack_C
    else
        error("Family has to be either A or C")
    end
    families = String[]
    seeds = Int[]
    ns = Int[]
    ms = Int[]
    bins = Bool[]
    gb_total_times = Float64[]
    normalform_times = Float64[]
    total_times = Float64[]
    solver_times = Float64[]
    pareto_sizes = Int[]
    gb_times = Vector{Float64}[]
    gb_sizes = Vector{Int}[]
    num_ips = Int[]
    for seed in 1:repetitions
        Random.seed!(seed)
        knapsack = generator(n, objectives=p, binary=binary, format="4ti2")
        filename = "knapsack_$(n)_$(p)_$(seed).dat"
        path = "./moip_instances/moip/"
        fullname = path * filename
        MultiObjectiveInstances.write_to_file(knapsack, fullname)
        _, _, stats = moip_gb_solve(fullname)
        push!(families, family)
        push!(seeds, seed)
        push!(ns, n)
        push!(ms, m)
        push!(bins, binary)
        push!(gb_total_times, stats.gb_total_time)
        push!(normalform_times, stats.normalform_time)
        push!(total_times, stats.total_time)
        push!(solver_times, stats.solver_time)
        push!(pareto_sizes, stats.pareto_size)
        push!(gb_times, stats.gb_times)
        push!(gb_sizes, stats.gb_sizes)
        push!(num_ips, stats.num_ips)
        flush(stdout)
    end
    df = DataFrame(
        "Family" => families,
        "Seed" => seeds,
        "n" => ns,
        "m" => ms,
        "Binary" => bins,
        "gb_total_time" => gb_total_times,
        "normalform_time" => normalform_times,
        "total_time" => total_times,
        "solver_time" => solver_times,
        "pareto_size" => pareto_sizes,
        "gb_times" => gb_times,
        "gb_sizes" => gb_sizes,
        "num_ips" => num_ips
    )
    CSV.write("moip_results_$(family)_$(n)_$(p).csv", df)
    return df
end

logfile = open("knapsack.log", "w")
logger = SimpleLogger(logfile)
global_logger(logger)

if length(ARGS) < 1
    error("Missing command line argument")
end

table = ARGS[1]

function produce_table(table :: String)
    if table == "4.15"
        #Table 4.15: 3 objectives, binary
        df1 = runsolve("A", 10, 3, 30, true)
        df2 = runsolve("A", 15, 3, 30, true)
        df = vcat(df1, df2)
        CSV.write("moip_results_tab_15.csv", df)
    elseif table == "4.16"
        #Table 4.16: 3 objectives, unbounded
        df1 = runsolve("A", 25, 3, 30, false)
        df2 = runsolve("A", 50, 3, 30, false)
        df3 = runsolve("A", 75, 3, 30, false)
        df4 = runsolve("A", 100, 3, 30, false)
        df5 = runsolve("C", 25, 3, 30, false)
        df6 = runsolve("C", 50, 3, 30, false)
        df7 = runsolve("C", 75, 3, 30, false)
        df8 = runsolve("C", 100, 3, 30, false)
        df = vcat(df1, df2, df3, df4, df5, df6, df7, df8)
        CSV.write("moip_results_tab_16.csv", df)
    elseif table == "4.17"
        #Table 4.17: 4 objectives, unbounded
        df1 = runsolve("A", 25, 4, 30, false)
        df2 = runsolve("A", 50, 4, 30, false)
        df3 = runsolve("A", 75, 4, 30, false)
        df4 = runsolve("C", 25, 4, 30, false)
        df5 = runsolve("C", 50, 4, 30, false)
        df6 = runsolve("C", 75, 4, 30, false)
        df = vcat(df1, df2, df3, df4, df5, df6)
        CSV.write("moip_results_tab_17.csv", df)
    elseif table == "4.18"
        #Table 4.18: 5 objectives, unbounded
        df1 = runsolve("A", 25, 5, 30, false)
        df2 = runsolve("A", 50, 5, 30, false)
        df3 = runsolve("A", 75, 5, 30, false)
        df4 = runsolve("C", 25, 5, 30, false)
        df5 = runsolve("C", 50, 5, 30, false)
        df6 = runsolve("C", 75, 5, 30, false)
        df = vcat(df1, df2, df3, df4, df5, df6)
        CSV.write("moip_results_tab_18.csv", df)
    else
        error("Unknown argument")
    end
end

println("Table 15")
produce_table("4.15")
println("Table 16")
produce_table("4.16")
println("Table 17")
produce_table("4.17")
println("Table 18")
produce_table("4.18")
