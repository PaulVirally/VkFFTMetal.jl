# VkFFTMetal.jl

Runs [VkFFT](https://github.com/DTolm/VkFFT) on `MtlArray`s. The package depends
on Metal.jl and VkFFT.jl, which is what activates VkFFT.jl's Metal extension. It
re-exports VkFFT.jl.

## Setup

TODO(jll): install instructions pending VkFFT_Metal_jll registration. Until
then, the libvkfft_path preference is the only way in.

`Pkg.add("VkFFTMetal")` installs the Julia side. VkFFT.jl calls
[a small C wrapper](https://github.com/PaulVirally/libvkfft) around VkFFT, and
there is no JLL for it yet, so build it yourself and point the package at the
shared library it produces:

```julia
using Preferences, VkFFT
set_preferences!(VkFFT, "libvkfft_path" => "/path/to/libvkfft.dylib")
```

Build it with `-DVKFFT_BACKEND=5`. That build needs macOS and the `metal-cpp`
headers, which come with the sources.

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

Metal has no double precision, so you get `Float32`, `ComplexF32` and the half
precisions. Metal.jl already refuses to allocate an `MtlArray` of `Float64` or
`ComplexF64`, and a plan asked for one anyway says so instead of returning a
VkFFT error code. Run double-precision transforms on a CUDA or OpenCL device.

## Do not plan inside an autorelease pool

VkFFT's Metal plan builder over-releases the strings it compiles its kernels
from, so a pool drained after the call crashes inside `objc_release`. VkFFT.jl
never opens a pool around planning, so this only hits code that wraps the call
itself, as in `Metal.@autoreleasepool VkFFT.plan_fft(x)`. Applying a plan is
fine and holds a pool of its own. This is an upstream bug with a fix pending in
[DTolm/VkFFT#227](https://github.com/DTolm/VkFFT/pull/227).

## Documentation

The entry points, the transform families, tuning and the per-backend capability
matrix are in the
[VkFFT.jl documentation](https://paulvirally.github.io/VkFFT.jl/stable/).
