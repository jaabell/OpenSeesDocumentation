# ASDPlasticMaterial3D: geostatic initialization with an elastic stage and K0.
#
# 1 x 1 x 4 m soil column (FourNodeTetrahedron), lateral rollers, fixed base,
# Mohr-Coulomb (phi = 30, c = 5 kPa), nu = 0.1. Elastic gravity gives
# sigma_xx / sigma_zz = nu / (1 - nu) = 0.111, below the active limit, so a
# plastic gravity step would yield the soil (here up to 0.25 near the top).
# The elastic stage keeps the gravity step elastic, then K0 is imposed and
# plasticity is switched on:
#   1. stage 0 (elastic) for all soil elements, apply self-weight
#   2. set sigma_xx = sigma_yy = K0 sigma_zz with K03D
#   3. stage 1 (elastoplastic) and continue
# Expected output:
#   stage 0, after gravity:            sxx/szz in (0.11111, 0.11111)
#   after K03D (no analysis step):     sxx/szz in (0.50000, 0.50000)
#   stage 1, after 5 zero-load steps:  sxx/szz in (0.50000, 0.50000)

wipe
model BasicBuilder -ndm 3 -ndf 3

set rho 2000.0
set g 9.81
set K0 0.5

nDMaterial ASDPlasticMaterial3D 1 MohrCoulomb_YF MohrCoulomb_PF LinearIsotropic3D_EL BackStress(NullHardeningTensorFunction): \
    Begin_Model_Parameters MC_phi 30 MC_c 5000 MC_ds 1e-4 MC_psi 0 MC_theta_T 29 \
        YoungsModulus 50e6 PoissonsRatio 0.1 MassDensity $rho InitialP0 -1.0e-3 End_Model_Parameters \
    Begin_Integration_Options f_absolute_tol 1e-3 n_max_iterations 60 Method Backward_Euler End_Integration_Options

# nodes: 4 corners per level, 5 levels
set nz 4
set n 0
for {set k 0} {$k <= $nz} {incr k} {
    foreach {i j} {0 0 1 0 1 1 0 1} { incr n; node $n $i $j $k; set vid($i,$j,$k) $n }
}
# 6 positively oriented tetrahedra per 1 m cube
set e 0
for {set k 0} {$k < $nz} {incr k} {
    set k1 [expr {$k + 1}]
    set c [list $vid(0,0,$k) $vid(1,0,$k) $vid(1,1,$k) $vid(0,1,$k) \
                $vid(0,0,$k1) $vid(1,0,$k1) $vid(1,1,$k1) $vid(0,1,$k1)]
    foreach t {{0 1 2 6} {0 2 3 6} {0 3 7 6} {0 7 4 6} {0 4 5 6} {0 5 1 6}} {
        incr e
        element FourNodeTetrahedron $e {*}[lmap q $t {lindex $c $q}] 1 0.0 0.0 [expr {-$rho * $g}]
    }
}
# lateral rollers, fixed base
foreach nd [getNodeTags] {
    lassign [nodeCoord $nd] x y z
    fix $nd [expr {$x < 1e-9 || $x > 1 - 1e-9}] [expr {$y < 1e-9 || $y > 1 - 1e-9}] [expr {$z < 1e-9}]
}

proc ratios {label} {
    set rmin 1e9; set rmax -1e9
    foreach el [getEleTags] {
        lassign [eleResponse $el material 1 stress] sxx syy szz
        set r [expr {$sxx / $szz}]
        set rmin [expr {min($rmin, $r)}]; set rmax [expr {max($rmax, $r)}]
    }
    puts [format "%-34s sxx/szz in (%.5f, %.5f)" $label $rmin $rmax]
}

# all stage and K0 changes go element by element through one parameter
parameter 1
foreach el [getEleTags] { addToParameter 1 element $el updateMaterialStage }
parameter 2
foreach el [getEleTags] { addToParameter 2 element $el K03D }

constraints Transformation
numberer RCM
system UmfPack
test NormUnbalance 1e-3 50
algorithm Newton
integrator LoadControl 0.1
analysis Static

# 1. elastic gravity
updateParameter 1 0
pattern Plain 1 Linear { eleLoad -ele {*}[getEleTags] -type -selfWeight 1 1 1 }
analyze 10
ratios "stage 0, after gravity:"
loadConst -time 0.0

# 2. K0 stress (sigma_zz < 0 in compression; K0 > 0 scales it)
updateParameter 2 $K0
ratios "after K03D (no analysis step):"

# 3. elastoplastic from here on
updateParameter 1 1
integrator LoadControl 0.0
analyze 5
ratios "stage 1, after 5 zero-load steps:"
