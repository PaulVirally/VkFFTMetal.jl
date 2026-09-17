module VkFFTMetal

using Metal
using Reexport
@reexport using VkFFT

# Nothing here refers to a name from the JLL, but VkFFTMetalExt lists it as a
# trigger alongside Metal, and a trigger has to be loaded rather than merely
# listed as a dependency for the extension to activate.
import VkFFT_Metal_jll

"""
    __init__()

Warns when VkFFT's Metal extension did not activate, which leaves this package doing nothing.

The check dispatches on Metal.MtlArray so it also catches any extension loaded
against a different version of VkFFT's backend interface. It remains a warning.
A machine with no Metal device should still be able to precompile a project that
depends on this package.

# Returns
- `nothing`
"""
function __init__()
    active = try
        VkFFT._backend(Metal.MtlArray{ComplexF32, 1, Metal.PrivateStorage}) === Val(:metal)
    catch
        false
    end
    active || @warn "VkFFT's Metal extension did not activate, so VkFFT.plan_fft cannot take an MtlArray. Check that Metal and VkFFT both precompiled properly." maxlog=1

    return nothing
end

end # module
