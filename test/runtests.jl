using Test
using VkFFTMetal
using VkFFTMetal.Metal: MtlArray

@testset "VkFFTMetal" begin
    delta = zeros(ComplexF32, 256, 4)
    delta[1, :] .= 1
    x = MtlArray(delta)
    p = VkFFT.plan_fft(x, 1)
    @test Array(p * x) ≈ ones(ComplexF32, 256, 4)
    @test Array(inv(p) * (p * x)) ≈ delta

    r = MtlArray(ones(Float32, 256))
    @test Array(VkFFT.plan_rfft(r) * r) ≈ [256; zeros(128)]
end
