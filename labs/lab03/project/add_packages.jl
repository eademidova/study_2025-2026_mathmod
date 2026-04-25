##!/usr/bin/env julia
## add_packages.jl
using Pkg
Pkg.activate(".") # Активируем текущий проект
## ОСНОВНЫЕ ПАКЕТЫ ДЛЯ РАБОТЫ
packages = [
"Graphs", # Организация проекта
"StatsBase", # Решение ОДУ
"GraphRecipes" # Визуализация
]
println("Установка базовых пакетов...")
Pkg.add(packages)
println("\n✅ Все пакеты установлены!")
println("Для проверки: using DrWatson, DifferentialEquations, Plots")
cd