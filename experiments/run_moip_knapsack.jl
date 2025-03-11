"""
Runs an epsilon-constraint based bi-objective solver over randomly generated
bi-objective knapsack instances.

Parameters:
- a string containing the desired families of instances (a substring of "ABCD")
or tables to reproduce (a substring of "123456")
- number of items for the knapsacks
- number of random instances of each family to be generated

If the number of a table is given, no other parameters are necessary.
"""

using MultiObjectiveInstances
using MultiObjectiveInstances.Knapsack

using IPGBs
using IPGBs.MultiObjectiveStats
using IPGBs.MultiObjectiveTools

using Logging
using Random
using DataFrames
using CSV
using ProgressBars

function runsolve(
    family :: String,
    n :: Int,
    m :: Int,
    p :: Int,
    repetitions :: Int;
    binary :: Bool = false,
    solver :: String = "IPGBs",
    algorithm :: String = "grobnecon"
)
    @assert family in ["A", "B", "C", "D"]
    println("Starting $n")
    generator = knapsack_A
    if family == "A"
        generator = knapsack_A
    elseif family == "B"
        generator = knapsack_B
    elseif family == "C"
        generator = knapsack_C
    elseif family == "D"
        generator = knapsack_D
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
    for seed in ProgressBar(1:repetitions)
        Random.seed!(seed)
        knapsack = generator(n, m, objectives = p, binary = binary)
        if algorithm == "grobnecon"
            knapsack = fourti2_stdform(knapsack)
            filename = "knapsack_$(n)_$(m)_$(p)_$(seed).dat"
            path = "./moip_instances/"
            fullname = path * filename
            MultiObjectiveInstances.write_to_file(knapsack, fullname)
            _, _, stats = moip_gb_solve(fullname, solver = solver)
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
        end
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
    CSV.write("results_$(family)_$(n).csv", df)
    return df
end

function moip_experiment(
    families :: String;
    n :: Int = 50,
    objectives :: Int = 2,
    repetitions :: Int = 10,
    binary :: Bool = false,
    solver :: String = "IPGBs",
    algorithm :: String = "grobnecon"
)
    #Set up the log file for this run
    logfile = open("knapsack.log", "w")
    logger = SimpleLogger(logfile, Logging.Debug)
    global_logger(logger)

    #Is the current code trying to reproduce some tables from Hartillo-Hermoso
    #et al (2019)?
    finished = false
    if families == "1"
        df1 = runsolve("A", 50, 1, 2, 30, algorithm=algorithm)
        df2 = runsolve("B", 50, 1, 2, 30, algorithm=algorithm)
        df3 = runsolve("C", 50, 1, 2, 30, algorithm=algorithm)
        df4 = runsolve("D", 50, 1, 2, 30, algorithm=algorithm)
        df = vcat(df1, df2, df3, df4)
        CSV.write("results_$(families).csv", df)
        finished = true
    elseif families == "2"
        df1 = runsolve("D", 60, 1, 2, 30, algorithm=algorithm)
        df2 = runsolve("D", 70, 1, 2, 30, algorithm=algorithm)
        df3 = runsolve("D", 80, 1, 2, 30, algorithm=algorithm)
        df4 = runsolve("D", 90, 1, 2, 30, algorithm=algorithm)
        df5 = runsolve("D", 100, 1, 2, 30, algorithm=algorithm)
        df = vcat(df1, df2, df3, df4, df5)
        CSV.write("results_$(families).csv", df)
        finished = true
    elseif families == "3"
        df1 = runsolve("A", 10, 1, 2, 30, binary = true, algorithm=algorithm)
        df2 = runsolve("A", 15, 1, 2, 30, binary = true, algorithm=algorithm)
        df3 = runsolve("A", 20, 1, 2, 30, binary = true, algorithm=algorithm)
        df4 = runsolve("A", 25, 1, 2, 30, binary = true, algorithm=algorithm)
        df5 = runsolve("A", 30, 1, 2, 30, binary = true, algorithm=algorithm)
        df = vcat(df1, df2, df3, df4, df5)
        CSV.write("results_$(families).csv", df)
        finished = true
    elseif families == "4"
        df1 = runsolve("A", 20, 2, 2, 30, algorithm=algorithm)
        df2 = runsolve("A", 25, 2, 2, 30, algorithm=algorithm)
        df3 = runsolve("A", 30, 2, 2, 30, algorithm=algorithm)
        df4 = runsolve("A", 35, 2, 2, 30, algorithm=algorithm)
        df5 = runsolve("A", 40, 2, 2, 30, algorithm=algorithm)
        df = vcat(df1, df2, df3, df4, df5)
        CSV.write("results_$(families).csv", df)
        finished = true
    elseif families == "5"
        df1 = runsolve("A", 20, 3, 2, 30, algorithm=algorithm)
        df2 = runsolve("A", 25, 3, 2, 30, algorithm=algorithm)
        df3 = runsolve("A", 30, 3, 2, 30, algorithm=algorithm)
        df4 = runsolve("A", 35, 3, 2, 30, algorithm=algorithm)
        df = vcat(df1, df2, df3, df4)
        CSV.write("results_$(families).csv", df)
        finished = true
    elseif families == "6"
        df1 = runsolve("A", 100, 1, 2, 10, algorithm=algorithm)
        df2 = runsolve("A", 200, 1, 2, 10, algorithm=algorithm)
        df3 = runsolve("A", 300, 1, 2, 10, algorithm=algorithm)
        df4 = runsolve("A", 400, 1, 2, 10, algorithm=algorithm)
        df5 = runsolve("A", 500, 1, 2, 10, algorithm=algorithm)
        df = vcat(df1, df2, df3, df4, df5)
        CSV.write("results_$(families).csv", df)
        finished = true
    end

    if finished
        return
    end

    if occursin("A", families)
        runsolve("A", n, 1, objectives, repetitions, solver=solver, binary=binary,
                 algorithm=algorithm)
    end
    if occursin("B", families)
        runsolve("B", n, 1, objectives, repetitions, solver=solver, binary=binary,
                 algorithm=algorithm)
    end
    if occursin("C", families)
        runsolve("C", n, 1, objectives, repetitions, solver=solver, binary=binary,
                 algorithm=algorithm)
    end
    if occursin("D", families)
        runsolve("D", n, 1, objectives, repetitions, solver=solver, binary=binary,
                 algorithm=algorithm)
    end
end

println("Starting family 1")
moip_experiment("1")
println("Starting family 2")
moip_experiment("2")
println("Starting family 3")
moip_experiment("3")
println("Starting family 4")
moip_experiment("4")
println("Starting family 5")
moip_experiment("5")
println("Starting family 6")
moip_experiment("6")
