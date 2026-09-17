# VkFFTMetal.jl

Runs [VkFFT](https://github.com/DTolm/VkFFT) on `MtlArray`s. The package depends
on Metal.jl and VkFFT.jl, which is what activates VkFFT.jl's Metal extension. It
re-exports VkFFT.jl.

## Setup

```julia
Pkg.add("VkFFTMetal")
```

That pulls in VkFFT_Metal_jll, which ships the prebuilt wrapper.To build the
wrapper yourself, see the [developer
docs](https://paulvirally.github.io/VkFFT.jl/stable/building/).

## Use

```julia
using VkFFTMetal, Metal, LinearAlgebra

x = MtlArray{ComplexF32}(undef, 256, 64)
copyto!(x, rand(ComplexF32, 256, 64))

p = VkFFT.plan_fft(x, 1) # transform along dimension 1, batch over dimension 2
y = p * x                # or mul!(y, p, x)
x2 = inv(p) * y          # normalized inverse, 1/N applied inside the kernel
```

## No Float64

Metal has no double precision (because the Apple Silicon hardware does not
support these calculations), so you can only use `Float32`, `ComplexF32` and the
half precisions `Float16`, `ComplexF16` (the latter is only supported on macOS
14 and later).

## Do not plan inside an autorelease pool

VkFFT's Metal plan builder over-releases the strings it compiles its kernels
from, so a pool drained after the call crashes inside `objc_release`. VkFFT.jl
never opens a pool around planning, so this only hits code that wraps the call
itself, as in `Metal.@autoreleasepool VkFFT.plan_fft(x)`. Applying a plan is
fine and holds a pool of its own. This is an upstream bug with a fix pending in
[DTolm/VkFFT#227](https://github.com/DTolm/VkFFT/pull/227).

## Documentation

The entry points, the transform families, tuning and the per-backend capability
matrix can be found in the [VkFFT.jl
documentation](https://paulvirally.github.io/VkFFT.jl/stable/).
