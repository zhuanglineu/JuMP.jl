#  Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

using JuMP, AxisArrays
using Base.Test

macro dummycontainer(expr, requestedtype)
    name = gensym()
    refcall, indexvars, indexsets, condition = JuMP.buildrefsets(expr, name)
    if condition == :()
        return JuMP.generatecontainer(Bool, indexvars, indexsets, requestedtype)
    else
        if requestedtype != :Auto && requestedtype != :Dict
            return :(error(""))
        end
        return JuMP.generatecontainer(Bool, indexvars, indexsets, :Dict)
    end
end

function containermatches(c1::AbstractArray,c2::AbstractArray)
    return typeof(c1) == typeof(c2) && size(c1) == size(c2)
end

containermatches(c1::Dict, c2::Dict) = (eltype(c1) == eltype(c2))
containermatches(c1, c2) = false

@testset "Container syntax" begin
    @test containermatches(@dummycontainer([i=1:10], Auto), Vector{Bool}(10))
    @test containermatches(@dummycontainer([i=1:10], Array), Vector{Bool}(10))
    @test containermatches(@dummycontainer([i=1:10], AxisArray), AxisArray(Vector{Bool}(10), Axis{:i}(1:10)))
    @test containermatches(@dummycontainer([i=1:10], Dict), Dict{Any,Bool}())

    @test containermatches(@dummycontainer([i=1:10,1:2], Auto), Matrix{Bool}(10,2))
    @test containermatches(@dummycontainer([i=1:10,1:2], Array), Matrix{Bool}(10,2))
    @test containermatches(@dummycontainer([i=1:10,n=1:2], AxisArray), AxisArray(Matrix{Bool}(10,2), Axis{:i}(1:10), Axis{:n}(1:2)))
    @test containermatches(@dummycontainer([i=1:10,1:2], Dict), Dict{Any,Bool}())

    @test containermatches(@dummycontainer([i=1:10,n=2:3], Auto), AxisArray(Matrix{Bool}(10,2), Axis{:i}(1:10), Axis{:n}(2:3)))
    @test_throws ErrorException @dummycontainer([i=1:10,2:3], Array)
    @test containermatches(@dummycontainer([i=1:10,n=2:3], AxisArray), AxisArray(Matrix{Bool}(10,2), Axis{:i}(1:10), Axis{:n}(2:3)))
    @test containermatches(@dummycontainer([i=1:10,n=2:3], Dict), Dict{Any,Bool}())


    S = Base.OneTo(10)
    @test containermatches(@dummycontainer([i=S], Auto), Vector{Bool}(10))
    @test containermatches(@dummycontainer([i=S], Array), Vector{Bool}(10))
    @test containermatches(@dummycontainer([i=S], AxisArray), AxisArray(Vector{Bool}(10), Axis{:i}(S)))
    @test containermatches(@dummycontainer([i=S], Dict), Dict{Any,Bool}())

    @test containermatches(@dummycontainer([i=S,1:2], Auto), Matrix{Bool}(10,2))
    @test containermatches(@dummycontainer([i=S,1:2], Array), Matrix{Bool}(10,2))
    @test containermatches(@dummycontainer([i=S,n=1:2], AxisArray), AxisArray(Matrix{Bool}(10,2), Axis{:i}(S), Axis{:n}(1:2)))
    @test containermatches(@dummycontainer([i=S,1:2], Dict), Dict{Any,Bool}())

    S = 1:10
    # Not type stable to return an Array by default even when S is one-based interval
    @test containermatches(@dummycontainer([i=S], Auto), AxisArray(Vector{Bool}(10), Axis{:i}(S)))
    @test containermatches(@dummycontainer([i=S], Array), Vector{Bool}(10))
    @test containermatches(@dummycontainer([i=S], AxisArray), AxisArray(Vector{Bool}(10), Axis{:i}(S)))
    @test containermatches(@dummycontainer([i=S], Dict), Dict{Any,Bool}())

    @test containermatches(@dummycontainer([i=S,n=1:2], Auto), AxisArray(Matrix{Bool}(10,2), Axis{:i}(S), Axis{:n}(1:2)))
    @test containermatches(@dummycontainer([i=S,1:2], Array), Matrix{Bool}(10,2))
    @test containermatches(@dummycontainer([i=S,n=1:2], AxisArray), AxisArray(Matrix{Bool}(10,2), Axis{:i}(S), Axis{:n}(1:2)))
    @test containermatches(@dummycontainer([i=S,1:2], Dict), Dict{Any,Bool}())

    # TODO: test case where S is index set not supported by AxisArrays (does this exist?)

    # Conditions
    @test containermatches(@dummycontainer([i=1:10; iseven(i)], Auto), Dict{Any,Bool}())
    @test_throws ErrorException @dummycontainer([i=1:10; iseven(i)], Array)
    @test_throws ErrorException @dummycontainer([i=1:10; iseven(i)], AxisArray)
    @test containermatches(@dummycontainer([i=1:10; iseven(i)], Dict), Dict{Any,Bool}())

    # Dependent indices
    @test containermatches(@dummycontainer([i=1:10, j=1:i], Auto), Dict{Any,Bool}())
    @test_throws ErrorException @dummycontainer([i=1:10, j=1:i], Array)
    @test_throws ErrorException @dummycontainer([i=1:10, j=1:i], AxisArray)
    @test containermatches(@dummycontainer([i=1:10, j=1:i], Dict), Dict{Any,Bool}())


end
