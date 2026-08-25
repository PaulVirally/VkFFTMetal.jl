# VkFFTMetal.jl

Runs [VkFFT](https://github.com/DTolm/VkFFT) on `MtlArray`s by loading VkFFT.jl
with its Metal backend. This package simply activates VkFFT's Metal extension
and re-exports VkFFT.

```julia
using VkFFTMetal, Metal, LinearAlgebra

x = MtlArray{ComplexF32}(undef, 1024, 64)
copyto!(x, rand(ComplexF32, 1024, 64))

p = VkFFT.plan_fft(x, 1) # transform along dimension 1, batch over dimension 2
y = p * x                # or mul!(y, p, x)
x2 = inv(p) * y          # normalized inverse, 1/N applied inside the kernel
```

Everything else (including the entry points, the plans, and the real transforms)
is documented in [VkFFT.jl](https://www.github.com/PaulVirally/VkFFT.jl).

## Setup

VkFFT.jl calls [a small C wrapper](https://www.github.com/PaulVirally/libvkfft)
around VkFFT, and until that wrapper ships as a JLL you need to build it
yourself and point the package to the resulting shared library:

```julia
using Preferences, VkFFT
set_preferences!(VkFFT, "libvkfft_path" => "/path/to/libvkfft.dylib")
```

Build it with `-DVKFFT_BACKEND=5` from the `libvkfft` sources. That build needs
macOS and the `metal-cpp` headers, both of which come with the sources.

TODO: once `VkFFT_Metal_jll` is registered it becomes a dependency for this
package, ships the wrapper as an artifact, and the preference above becomes an
override for people who want their own build.

## Float32 only

Metal has no double precision, so `ComplexF32` and `Float32` are the whole
story here. Metal.jl already refuses to allocate an `MtlArray` of `Float64` or
`ComplexF64`, and a plan asked for one anyway says so rather than returning a
VkFFT error code. Run double-precision transforms on a CUDA or OpenCL device.

## Do not plan inside an autorelease pool

Building a plan calls into VkFFT's Metal plan builder, which over-releases the
strings it compiles its kernels from. Draining a pool afterwards then crashes
the process inside `objc_release`. VkFFT.jl never opens a pool around planning,
so this only bites if you wrap the call yourself:

```julia
p = VkFFT.plan_fft(x)                    # fine
Metal.@autoreleasepool VkFFT.plan_fft(x) # segfaults when the pool drains
```

Applying a plan is unaffected, and does hold a pool of its own.

This is not an issue for 99% of applications. The problem might occur if you
have Julia embedded in a Cocoa application draining a pool constantly on the
main thread. In that case, plan from a worker task there. The over-release is an
upstream VkFFT bug with a fix pending in
[DTolm/VkFFT#227](https://github.com/DTolm/VkFFT/pull/227).

## Views

A buffer enters a Metal transform at its own first element, because the launch
parameters carry no offset. Metal.jl represents a contiguous view as another
`MtlArray` carrying a byte offset, so `view(x, 3:6)` is refused with advice to
copy it first, while `view(x, 1:4)` plans and runs as itself.

## Status

Complex-to-complex and real-to-complex transforms, `ComplexF32` and `Float32`.
No DCT/DST, no fused convolution, no zero-padding, no half or quad precision, no
autotuner and no kernel binary cache yet.
