# ASDPlasticMaterial3D example: VonMises_YF + ConstantDilatancy_PF
#
# A single 8-node brick is driven in homogeneous uniaxial compressive strain
# (eps_xx imposed, eps_yy = eps_zz = 0) past yield, for three dilatancy values.
# ConstantDilatancy_PF uses m = n_dev - (D/3) I with |n_dev| = 1, so the
# accumulated plastic strain satisfies
#     plastic volumetric strain / norm(deviatoric plastic strain) = -D
# (positive D gives negative plastic volumetric change).
proc run {D} {
    wipe; model BasicBuilder -ndm 3 -ndf 3
    set i 1
    foreach z {0 1} { foreach y {0 1} { foreach x {0 1} { node $i $x $y $z; incr i } } }
    nDMaterial ASDPlasticMaterial3D 1 VonMises_YF ConstantDilatancy_PF LinearIsotropic3D_EL \
        BackStress(TensorLinearHardeningFunction):YieldStress(ScalarLinearHardeningFunction): \
        Begin_Internal_Variables YieldStress 100.0 End_Internal_Variables \
        Begin_Model_Parameters YoungsModulus 1e5 PoissonsRatio 0.3 Dilatancy $D \
            TensorLinearHardeningParameter 0 ScalarLinearHardeningParameter 0 MassDensity 0 End_Model_Parameters
    element stdBrick 1 1 2 4 3 5 6 8 7 1
    # homogeneous strain eps_xx = -lambda*1e-2 (others 0) imposed on all nodes
    timeSeries Linear 1
    pattern Plain 1 1 { for {set n 1} {$n <= 8} {incr n} { set x [lindex [nodeCoord $n] 0]; sp $n 1 [expr -1e-2*$x]; sp $n 2 0; sp $n 3 0 } }
    constraints Penalty 1e12 1e12; numberer Plain; system FullGeneral; test NormDispIncr 1e-10 50; algorithm Newton
    integrator LoadControl 0.05; analysis Static
    if {[analyze 20] != 0} { return "analysis FAILED" }
    set p [eleResponse 1 material 1 pstrains]
    set vol [expr [lindex $p 0]+[lindex $p 1]+[lindex $p 2]]
    set n 0.0
    foreach k {0 1 2} { set d [expr [lindex $p $k]-$vol/3.0]; set n [expr $n+$d*$d] }
    set n [expr sqrt($n)]
    if {$n == 0} { return "no plastic strain" }
    return [format "D=%+.2f  pstrain(xx,yy,zz)=(%.4e %.4e %.4e)  vol/|dev| = %+.6f  expected %+.2f" $D [lindex $p 0] [lindex $p 1] [lindex $p 2] [expr $vol/$n] [expr -$D]]
}
foreach D {0.2 0.0 -0.2} { puts "CD [run $D]" }
