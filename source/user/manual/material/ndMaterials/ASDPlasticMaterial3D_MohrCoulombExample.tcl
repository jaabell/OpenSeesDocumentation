# ASDPlasticMaterial3D - MohrCoulomb_YF / MohrCoulomb_PF
#
# Unconfined compression test of a single 8-node brick. With sigma_3 = 0,
# the Mohr-Coulomb criterion gives the standard unconfined compressive
# strength:
#
#   sigma_1 = 2*c*cos(phi)/(1-sin(phi))

set phi_deg 30.0
set c 10000.0
set pi 3.14159265358979
set phi [expr $phi_deg*$pi/180.0]
set ucs [expr 2.0*$c*cos($phi)/(1.0-sin($phi))]

wipe
model BasicBuilder -ndm 3 -ndf 3
set i 1
foreach z {0 1} { foreach y {0 1} { foreach x {0 1} { node $i $x $y $z; incr i } } }
foreach n {1 2 3 4} { fix $n 0 0 1 }
fix 1 1 1 1; fix 2 0 1 1; fix 3 1 0 1

nDMaterial ASDPlasticMaterial3D 1 MohrCoulomb_YF MohrCoulomb_PF LinearIsotropic3D_EL BackStress(NullHardeningTensorFunction): \
    Begin_Internal_Variables BackStress 0 0 0 0 0 0 End_Internal_Variables \
    Begin_Model_Parameters \
        InitialP0 -1.0e-3 MC_c $c MC_ds 1e-8 MC_phi $phi_deg MC_psi 0.0 \
        MassDensity 0 PoissonsRatio 0.3 YoungsModulus 50e6 \
    End_Model_Parameters \
    Begin_Integration_Options \
        integration_method Backward_Euler tangent_type Secant \
        f_absolute_tol 1e-4 stress_absolute_tol 1e-2 n_max_iterations 50 \
        return_to_yield_surface Disabled \
    End_Integration_Options
element stdBrick 1 1 2 4 3 5 6 8 7 1

timeSeries Linear 1
pattern Plain 1 1 { foreach n {5 6 7 8} { sp $n 3 -1.0 } }
constraints Transformation; numberer RCM; system FullGeneral
test NormDispIncr 1e-8 100; algorithm Newton
set du 2e-5
integrator LoadControl $du; analysis Static

set peak 0.0
for {set k 0} {$k < 60} {incr k} {
    if {[analyze 1] != 0} { puts "step $k failed"; break }
    set szz [lindex [eleResponse 1 material 1 stress] 2]
    if {[expr -$szz] > $peak} { set peak [expr -$szz] }
}

puts [format "MohrCoulomb unconfined compression: got (peak) = %.4e Pa   expected (2c*cos(phi)/(1-sin(phi))) = %.4e Pa   rel.err = %.2e" $peak $ucs [expr abs($peak-$ucs)/$ucs]]
