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

using JuMP, GLPK, Base.Test
const MOI = MathOptInterface

set_type(c::JuMP.ConstraintRef{JuMP.Model, MathOptInterface.ConstraintIndex{F,S}}) where {F,S} = S
function MOI.modify!(m::JuMP.Model, c::JuMP.ConstraintRef, change::MOI.AbstractFunctionModification)
    MOI.modify!(c.m.moibackend, JuMP.index(c), change)
end
MOI.ScalarCoefficientChange(x::JuMP.VariableRef, v) = MOI.ScalarCoefficientChange(JuMP.index(x), v)

function setconstant(c::JuMP.ConstraintRef, rhs::Float64)
    new_set = set_type(c)(rhs)
    MOI.set!(c.m, MOI.ConstraintSet(), c, new_set)
end

function setcoefficient(c::JuMP.ConstraintRef, x::JuMP.VariableRef, value::Float64)
    MOI.modify!(c.m, c, MOI.ScalarCoefficientChange(x, value))
end

m = Model(optimizer = GLPKOptimizerLP())

@variable(m, 0 <= x <= 2)
@variable(m, 0 <= y <= 30)

@objective(m, Max, 5x + 3y)
c = @constraint(m, 1x + 5y <= 3.0)

JuMP.optimize(m)

@test JuMP.objectivevalue(m) == 10.6
@test JuMP.resultvalue(x)    == 2.0
@test JuMP.resultvalue(y)    == 0.2

setconstant(c, 4.0)

JuMP.optimize(m)

@test JuMP.objectivevalue(m) == 11.2
@test JuMP.resultvalue(x)    == 2.0
@test JuMP.resultvalue(y)    == 0.4

setcoefficient(c, x, 2.0)

JuMP.optimize(m)

@test JuMP.objectivevalue(m) == 10.0
@test JuMP.resultvalue(x)    == 2.0
@test JuMP.resultvalue(y)    == 0.0

setconstant(c, 3.0)

JuMP.optimize(m)

@test JuMP.objectivevalue(m) == 7.5
@test JuMP.resultvalue(x)    == 1.5
@test JuMP.resultvalue(y)    == 0.0
