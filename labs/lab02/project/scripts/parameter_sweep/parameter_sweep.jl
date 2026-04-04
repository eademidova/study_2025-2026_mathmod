using DrWatson
@quickactivate "project"
using Distributions, Statistics, Plots, StatsPlots, JLD2, Random, CSV, DataFrames

include(srcdir("simulation.jl"))

base_params = Dict(
:T => 24.0,
:num_hours_for_est => 10000
)

λ_values = [2.0, 5.0, 8.0, 12.0, 15.0]

Random.seed!(42)

parametric_plots_dir = plotsdir("parameter_sweep")
mkpath(parametric_plots_dir)

summary = Dict{Float64, Dict}()
println("Запуск параметрического исследования...")
for λ in λ_values

params = merge(base_params, Dict(:λ => λ))

filename = datadir("attack_sim", savename(params, "jld2"))

if isfile(filename)
    println("Загрузка существующих данных для λ = $λ из $filename")
@load filename data
else
println("Выполнение симуляции для λ = $λ")

res = simulate_attacks(λ, params[:T])
hourly_sample = rand(Poisson(λ), params[:num_hours_for_est])
emp_prob = count(hourly_sample .> 10) / params[:num_hours_for_est]
theor_prob = 1 - cdf(Poisson(λ), 10)
data = Dict(
:hourly_counts => res.hourly_counts,
:intervals => res.intervals,
:attack_times => res.attack_times,
:emp_prob => emp_prob,
:theor_prob => theor_prob
)

@save filename data params
println("Результаты сохранены в $filename")
end

hourly_counts = data[:hourly_counts]
intervals = data[:intervals]
attack_times = data[:attack_times]

p1 = histogram(hourly_counts, bins = 0:maximum(hourly_counts), normalize = :probability,
label = "Эмпирическая частота", xlabel = "Число атак за час", ylabel = "Вероятность")
x_vals = 0:maximum(hourly_counts)
theor_probs = pdf.(Poisson(λ), x_vals)
plot!(p1, x_vals, theor_probs, line = :stem, marker = :circle, label = "Теоретическое Пуассона(λ=$λ)", lw=2)
title!(p1, "Распределение числа атак за час (λ=$λ)")

p2 = plot(attack_times, 1:length(attack_times), label =
"Реализация", xlabel = "Время (ч)", ylabel = "Накопленное
число атак")


plot!(p2, 0:0.1:params[:T], λ*(0:0.1:params[:T]), label = "Среднее λ·t", ls = :dash)
title!(p2, "Накопленное число атак в течение $(params[:T]) ч (λ=$λ)")

p3 = histogram(intervals, bins = 30, normalize = :pdf, label = "Эмпирическая плотность", xlabel = "Интервал (ч)", ylabel = "Плотность")
x_dens = range(0, maximum(intervals), length=100)
theor_dens = pdf.(Exponential(1/λ), x_dens)
plot!(p3, x_dens, theor_dens, label = "Экспоненциальная плотность", lw=2)
title!(p3, "Распределение интервалов между атаками (λ=$λ)")

p4 = qqplot(Exponential(1/λ), intervals, qqline = :identity,
xlabel = "Теоретические квантили", ylabel = "Эмпирические квантили",
title = "QQ-plot интервалов (λ=$λ)")

combined = plot(p1, p2, p3, p4, layout = (2,2), size = (1000, 800))

plot_filename = joinpath(parametric_plots_dir, "attack_sim_λ=$(λ).png")
savefig(combined, plot_filename)
println("Детальные графики для λ=$λ сохранены в $plot_filename")

summary[λ] = Dict(
:emp_prob => data[:emp_prob],
:theor_prob => data[:theor_prob],
:filename => filename
)
println("λ = $λ: теоретическая вероятность = $(data[:theor_prob]), эмпирическая = $(data[:emp_prob])")
end

summary_filename = datadir("parameter_sweep", "summary_λ_values.jld2")
@save summary_filename λ_values summary
println("Сводные данные сохранены в $summary_filename")

λs = [λ for λ in λ_values]
theor_probs = [summary[λ][:theor_prob] for λ in λs]
emp_probs = [summary[λ][:emp_prob] for λ in λs]
p = plot(λs, [theor_probs emp_probs],
label = ["Теоретическая P(>10)" "Эмпирическая P(>10)"],
marker = :circle,
xlabel = "Интенсивность λ (атак/час)",
ylabel = "Вероятность P(>10)",
title = "Зависимость вероятности от интенсивности атак")
global_plot_path = plotsdir("parameter_sweep.png")
savefig(p, global_plot_path)
println("Общий график зависимости сохранён в $global_plot_path")

df = DataFrame(λ = λs, theoretical = theor_probs, empirical = emp_probs)
CSV.write(datadir("parameter_sweep", "summary.csv"), df)
println("Таблица сохранена в ", datadir("parameter_sweep", "summary.csv"))
