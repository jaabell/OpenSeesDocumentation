# ASDPlasticMaterial3D - HoekBrown_YF / HoekBrown_PF
#
# Unconfined compression test of a single 8-node brick. With sigma_3 = 0,
# the generalized Hoek-Brown criterion reduces to sigma_1 = sigma_ci*s^a,
# the rock-mass unconfined compressive strength (Hoek & Brown 2018).
#
#   mb = mi*exp((GSI-100)/(28-14D))
#   s  = exp((GSI-100)/(9-3D))
#   a  = 0.5 + (exp(-GSI/15) - exp(-20/3))/6
#
# GSI=50, mi=10, D=0 (mb is not needed for this check, only s and a).

set sigci 50.0e6
set GSI 50.0
set s [expr exp(($GSI-100.0)/9.0)]
set a [expr 0.5 + (exp(-$GSI/15.0) - exp(-20.0/3.0))/6.0]
set ucs [expr $sigci * pow($s,$a)]

wipe
model BasicBuilder -ndm 3 -ndf 3
set i 1
foreach z {0 1} { foreach y {0 1} { foreach x {0 1} { node $i $x $y $z; incr i } } }
# Minimal supports: bottom face rollers (z fixed), one corner pinned to remove
# the remaining rigid-body modes.
foreach n {1 2 3 4} { fix $n 0 0 1 }
fix 1 1 1 1; fix 2 0 1 1; fix 3 1 0 1

nDMaterial ASDPlasticMaterial3D 1 HoekBrown_YF HoekBrown_PF LinearIsotropic3D_EL BackStress(NullHardeningTensorFunction): \
    Begin_Model_Parameters \
        HB_sigci $sigci HB_GSI $GSI HB_mi 10 HB_D 0 HB_mb_psi 0.0 HB_ds 1e-6 \
        YoungsModulus 10e9 PoissonsRatio 0.25 MassDensity 0 \
    End_Model_Parameters \
    Begin_Integration_Options \
        integration_method Backward_Euler tangent_type Secant \
    End_Integration_Options
element stdBrick 1 1 2 4 3 5 6 8 7 1

# Compress the top face (z = 1) downwards.
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

puts [format "HoekBrown unconfined compression: got (peak) = %.4e Pa   expected (sigma_ci*s^a) = %.4e Pa   rel.err = %.2e" $peak $ucs [expr abs($peak-$ucs)/$ucs]]
