#  Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

validarrayindexset(::Base.OneTo) = true
validarrayindexset(r::UnitRange) = start(r) == 1
validarrayindexset(s) = false

"""
    generatecontainer(T, indexvars, indexsets, requestedtype)

Return *code* that generates a container for objects of type `T` given the index variables,
index sets, and `requestedtype`. `requestedtype` may be
one of `:Array`, `:AxisArray`, `:Dict`, or `:Auto`. Return error-producing code if
requested type is incompatible. For the case of `:None`, the following rules are
used to determine the appropriate container:

1. If all index sets are either explicit `Expr(:(:), 1, B)` objects for any `B` or symbols which refer to objects of type `Base.OneTo`, then an `Array` is generated of the appropriate size. Types of symbols/expressions are not known at compile time, so we defer to type-safe functions to check the `Base.OneTo` condition.

2. If condition (1) does not hold, and the index sets are independent (the index variable for one set does not appear in the definition of another), then an `AxisArray` is generated of the appropriate size.

3. Otherwise, generate an empty `Dict{Any,T}`.

### Examples

    generatecontainer(Variable, [:i,:j], [:(1:N), :(1:T)], :None)
    # Returns code equivalent to:
    # :(Array{Variable}(length(1:N), length(1:T))

    generatecontainer(Variable, [:i,:j], [:(1:N), :(2:T)], :None)
    # Returns code equivalent to:
    # :(AxisArray(Array{Variable}(length(1:N), length(2:T)), \$indexvars...))

    generatecontainer(Variable, [:i,:j], [:(1:N), :(S)], :None)
    # Returns code that generates an Array if S is of type Base.OneTo,
    # otherwise an AxisArray.

    generatecontainer(Variable, [:i,:j], [:(1:N), :(1:j)], :None)
    # Returns code equivalent to:
    # :(Dict{Any,Variable}())
"""
function generatecontainer(T, indexvars, indexsets, requestedtype)
    hasdependent = hasdependentsets(indexvars,indexsets)
    onetosets = falses(length(indexsets))
    for (i,indexset) in enumerate(indexsets)
        s = isexpr(indexset,:escape) ? indexset.args[1] : indexset
        if isexpr(s,:(:)) && length(s.args) == 2 && s.args[1] == 1
            onetosets[i] = true
        end
    end

    if requestedtype == :Dict || (requestedtype == :Auto && hasdependent)
        return :(Dict{Any,$T}())
    end

    sizes = Expr(:tuple, [:(length($rng)) for rng in indexsets]...)
    arrayexpr = :(Array{$T}($sizes...))

    if requestedtype == :Array
        hasdependent && return :(error("Unable to create requested Array because index sets are dependent."))
        if all(onetosets)
            return arrayexpr
        else
            # all sets must be one-based intervals
            condition = Expr(:&&)
            for (i,indexset) in enumerate(indexsets)
                if !onetosets[i]
                    push!(condition.args, Expr(:call, :(JuMP.validarrayindexset), indexset))
                end
            end
            return :($condition || error("Index set for array is not one-based interval."); $arrayexpr)
        end
    end

    axisexpr = :(AxisArrays.AxisArray(Array{$T}($sizes...)))
    for (indexvar, indexset) in zip(indexvars, indexsets)
        push!(axisexpr.args, :(AxisArrays.Axis{$(quot(indexvar))}($indexset)))
    end

    if requestedtype == :AxisArray
        hasdependent && return :(error("Unable to create requested AxisArray because index sets are dependent."))
        return axisexpr
    end

    @assert requestedtype == :Auto
    if all(onetosets) # definitely Array
        return arrayexpr
    end

    # Fallback, we have to decide once we know the types of the symbolic sets
    condition = Expr(:&&)
    for (i,indexset) in enumerate(indexsets)
        if !onetosets[i]
            push!(condition.args, Expr(:call, :isa, indexset, :(Base.OneTo)))
        end
    end

    # TODO: check type stability
    return :(if $condition; $arrayexpr; else $axisexpr; end)
end
