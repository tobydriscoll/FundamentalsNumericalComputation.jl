module FundamentalsNumericalComputation

export FNC
FNC = FundamentalsNumericalComputation

using Reexport

@reexport using LinearAlgebra
@reexport using SparseArrays
@reexport using Polynomials
@reexport using NLsolve
@reexport using DifferentialEquations
@reexport using Plots
@reexport using DataFrames 
@reexport using Interpolations

@info "Exporting: LinearAlgebra,SparseArrays,Polynomials,NLsolve,Interpolations,DifferentialEquations,DataFrames,Plots"

include("chapter01.jl")
include("chapter02.jl")
include("chapter03.jl")
include("chapter04.jl")
include("chapter05.jl")
include("chapter06.jl")
include("chapter08.jl")
include("chapter09.jl")
include("chapter10.jl")
include("chapter11.jl")
include("chapter13.jl")

end
