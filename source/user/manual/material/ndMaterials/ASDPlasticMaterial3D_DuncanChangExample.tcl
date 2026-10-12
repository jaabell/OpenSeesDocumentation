# ASDPlasticMaterial3D - DuncanChang_EL
#
# Demonstrates that the four DuncanChang_EL parameters land under their own,
# distinct names (ReferenceYoungsModulus / ReferencePressure /
# DuncanChang_MaxSigma3 / DuncanChang_n) rather than colliding with the
# generic "YoungsModulus" used by LinearIsotropic3D_EL. Also shows that
# DuncanChang_EL is compiled together with a "standard" yield function
# (MohrCoulomb_YF here), not just a dedicated one.
#
# This script only instantiates the material (no analysis/elements) and
# relies on the material's own Print() output, which echoes every parameter
# by name, to confirm the four values below are read back correctly.

wipe
model BasicBuilder -ndm 3 -ndf 3
foreach z {0 1} { foreach y {0 1} { foreach x {0 1} { node [expr 1+4*$z+2*$y+$x] $x $y $z } } }

nDMaterial ASDPlasticMaterial3D 1 MohrCoulomb_YF MohrCoulomb_PF DuncanChang_EL BackStress(NullHardeningTensorFunction): \
    Begin_Internal_Variables BackStress 0 0 0 0 0 0 End_Internal_Variables \
    Begin_Model_Parameters \
        InitialP0 -1.0e-3 MC_c 10000 MC_ds 1e-8 MC_phi 30 MC_psi 0 \
        MassDensity 1600 PoissonsRatio 0.3 \
        ReferenceYoungsModulus 500.0 ReferencePressure 100000.0 \
        DuncanChang_MaxSigma3 200000.0 DuncanChang_n 0.5 \
    End_Model_Parameters \
    Begin_Integration_Options \
        integration_method Backward_Euler tangent_type Secant \
        f_absolute_tol 1e-4 stress_absolute_tol 1e-2 n_max_iterations 50 \
        return_to_yield_surface Disabled \
    End_Integration_Options

puts "DuncanChang_EL parameters echoed by the material's own Print() above should show:"
puts "  ReferenceYoungsModulus = 500   PoissonsRatio = 0.3"
puts "  ReferencePressure = 100000   DuncanChang_MaxSigma3 = 200000   DuncanChang_n = 0.5"
puts "(each under its own distinct name, not colliding with YoungsModulus)"
