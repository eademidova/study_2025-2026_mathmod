using DrWatson
@quickactivate "project"
include(srcdir("simulation.jl"))
println("Запуск симуляций...")
results = main_simulations()
println("Готово! Сохранено строк: ", nrow(results))
