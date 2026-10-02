# example_staged_tri.tcl
#
# Verifies the -doInitDisp option of Tri31 (feat/tri-init-disp).
#
# Scenario: a 1x1 unit-square "layer 1" made of two Tri31 CST elements is
# sheared by prescribing ux = 0.01 on its top edge (nodes 3,4), bottom edge
# (nodes 1,2) fixed.  After that deformation is committed, a "layer 2" of
# Tri31 elements is added on top, connecting to the now-displaced nodes 3,4
# and brand-new (undisplaced, pinned) nodes.
#
# Without -doInitDisp, the new layer computes strain from the *absolute*
# trial displacement of its nodes, so it inherits the pre-existing 0.01
# shear of nodes 3,4 as if it were new deformation -> nonzero stress at the
# moment it is added, with no further loading applied.
#
# With -doInitDisp 1, Tri31::setDomain() captures each node's displacement
# at the moment the element is added (initDisp[i] = getDisp()), and
# Tri31::update() uses (getTrialDisp() - initDisp) instead of the raw trial
# displacement.  Since nothing moves after the new elements are added, the
# effective strain is exactly zero -> zero stress.
#
# Hand calculation (CST, E=1000, nu=0, so D33 = E/2 = 500):
#   Layer 1 shear strain gamma_xy = 0.01  ->  sigma_xy = 500*0.01 = 5.0
#   Layer 2, no flag: with this vertex labeling the inherited node
#     displacements give gamma_xy = -0.01 -> sigma_xy = -5.0 (nonzero: the
#     new element "feels" the pre-existing deformation of nodes 3,4)
#   Layer 2, with flag: effective relative displacement = 0 -> sigma_xy = 0.0

wipe
model basic -ndm 2 -ndf 2

# ---- layer 1: unit square (0,0)-(1,0)-(1,1)-(0,1), two CST triangles ----
node 1 0.0 0.0
node 2 1.0 0.0
node 3 1.0 1.0
node 4 0.0 1.0

fix 1 1 1
fix 2 1 1
fix 3 0 1
fix 4 0 1

nDMaterial ElasticIsotropic 1 1000.0 0.0

element Tri31 1  1 2 3  1.0 PlaneStrain 1
element Tri31 2  1 3 4  1.0 PlaneStrain 1

# prescribe ux = 0.01 on the top edge (nodes 3,4) via a Plain pattern
pattern Plain 1 "Linear" {
    sp 3 1 0.01
    sp 4 1 0.01
}

constraints Penalty 1.0e14 1.0e14
numberer RCM
system BandGeneral
test NormDispIncr 1.0e-12 10
algorithm Newton
integrator LoadControl 1.0
analysis Static
analyze 1

puts "---- layer 1 (after shearing) ----"
set s1 [eleResponse 1 stress]
set s2 [eleResponse 2 stress]
puts "element 1 stress (sxx syy sxy) = $s1"
puts "element 2 stress (sxx syy sxy) = $s2"

# ---- layer 2: added on top of the deformed layer 1 ----
# nodes 5,6: new layer, WITHOUT -doInitDisp
node 5 1.0 2.0
node 6 0.0 2.0
fix 5 1 1
fix 6 1 1

# nodes 7,8: new layer, WITH -doInitDisp 1
node 7 1.0 2.0
node 8 0.0 2.0
fix 7 1 1
fix 8 1 1

# no flag -> default do_init_disp = false
element Tri31 3  3 4 6  1.0 PlaneStrain 1
element Tri31 4  3 6 5  1.0 PlaneStrain 1

# -doInitDisp 1 -> strain measured relative to displacement at setDomain()
element Tri31 5  3 4 8  1.0 PlaneStrain 1 -doInitDisp 1
element Tri31 6  3 8 7  1.0 PlaneStrain 1 -doInitDisp 1

# re-run the (now larger) domain with zero additional load increment so
# that update()/getStress() reflect the current (unchanged) nodal state
integrator LoadControl 0.0
analyze 1

set s3 [eleResponse 3 stress]
set s4 [eleResponse 4 stress]
set s5 [eleResponse 5 stress]
set s6 [eleResponse 6 stress]

puts "---- layer 2 (just added, no further loading) ----"
puts "element 3 (no -doInitDisp) stress = $s3   (expected sxy = -5.0)"
puts "element 4 (no -doInitDisp) stress = $s4   (expected sxy = -5.0)"
puts "element 5 (-doInitDisp 1)  stress = $s5   (expected sxy = 0.0)"
puts "element 6 (-doInitDisp 1)  stress = $s6   (expected sxy = 0.0)"

set sxy3 [lindex $s3 2]
set sxy4 [lindex $s4 2]
set sxy5 [lindex $s5 2]
set sxy6 [lindex $s6 2]

set tol 1.0e-9
set pass 1
if {abs($sxy3-(-5.0)) > 1.0e-6} {set pass 0}
if {abs($sxy4-(-5.0)) > 1.0e-6} {set pass 0}
if {abs($sxy5-0.0) > $tol} {set pass 0}
if {abs($sxy6-0.0) > $tol} {set pass 0}

if {$pass} {
    puts "PASS: no-flag elements reproduce inherited shear stress (-5.0); -doInitDisp elements are stress-free (0.0)"
} else {
    puts "FAIL: see values above"
}
