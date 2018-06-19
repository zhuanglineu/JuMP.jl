#  Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
#############################################################################
# JuMP
# An algebraic modeling langauge for Julia
# See http://github.com/JuliaOpt/JuMP.jl
#############################################################################
# basic.jl
#
# Solves a simple LP:
# max 5x + 3y
#  st 1x + 5y <= 3
#      0 <= x <= 2
#      0 <= y <= 30
#############################################################################

using JuMP, GLPK

m = Model(optimizer = GLPKOptimizerLP())

@variable(m, 0 <= x <= 2)
@variable(m, 0 <= y <= 30)

@objective(m, Max, 5x + 3y)
c = @constraint(m, 1x + 5y <= 3.0)

const MOI = MathOptInterface
function setrhs(c, rhs)
    moi = c.m.moibackend
    MOI.set!(moi, MOI.ConstraintSet(), c.index, MOI.set_type(c.index)(rhs))
end

print(m)

JuMP.optimize(m)

println("Objective value: ", JuMP.objectivevalue(m))
println("x = ", JuMP.resultvalue(x))
println("y = ", JuMP.resultvalue(y))

setrhs(c, 4.0)

JuMP.optimize(m)

println("Objective value: ", JuMP.objectivevalue(m))
println("x = ", JuMP.resultvalue(x))
println("y = ", JuMP.resultvalue(y))
