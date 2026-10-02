# example_lumped_explicit.tcl
#
# Demonstrates "system Diagonal" vs "system Diagonal -lumped" when the
# assembled mass matrix is NOT diagonal (consistent mass element).
#
# Model: a single 1-D Truss element (2 nodes, 1 DOF each), free in space,
# with a consistent (non-diagonal) mass matrix (element Truss ... -cMass 1).
#
# For a 1-D truss of length L, area A, density rho, the consistent mass
# matrix is
#     M = (rho*A*L/6) * [ 2  1 ]
#                       [ 1  2 ]
# and the (correct) row-sum lumped mass at each node is
#     m_lumped = rho*A*L/2   (= row sum of M, same as the standard lumped
#                              truss mass matrix)
#
# If a uniform acceleration field a0 (same at both nodes) is imposed, the
# consistent nodal inertial force is F = M*[a0,a0]^T = (row sum)*a0 at each
# node, i.e. F_i = m_lumped * a0.
#
# integrator ExplicitDifference forms the system tangent as exactly M
# (addMtoTang(), coefficient 1) and, starting from rest, solves  M*a = F
# in a single pass through "system Diagonal<...>"/"algorithm Linear".
# So applying F_i = m_lumped*a0 at both nodes and solving for the
# resulting acceleration is a direct, hand-checkable probe of what each
# diagonal solver actually put on the diagonal of A:
#
#   system Diagonal          -> A_ii = M_ii only (off-diagonals dropped)
#                                a_computed = F / M_ii           (WRONG)
#   system Diagonal -lumped  -> A_ii = row-sum of M (= m_lumped)
#                                a_computed = F / m_lumped = a0  (CORRECT)

set rho 6.0
set L   1.0
set A   1.0
set a0  2.0

# row-sum (physically correct) lumped nodal mass and consistent diagonal entry
set m_lumped   [expr 0.5*$rho*$A*$L]        ;# = 3.0
set m_diag     [expr 2.0*$rho*$A*$L/6.0]    ;# = 2.0  (consistent M_ii)
set totalMass  [expr $rho*$A*$L]            ;# = 6.0  (physical total mass)

set F [expr $m_lumped*$a0]                  ;# = 6.0, consistent nodal force

proc buildModel {lumped} {
    global rho L A F

    wipe
    model basic -ndm 1 -ndf 1

    node 1 0.0
    node 2 1.0

    uniaxialMaterial Elastic 1 100.0

    # consistent (non-diagonal) mass matrix: -cMass 1
    element Truss 1 1 2 $A 1 -rho $rho -cMass 1

    timeSeries Constant 1 -factor 1.0
    pattern Plain 1 1 {
        load 1 $F
        load 2 $F
    }

    constraints Plain
    numberer Plain
    if {$lumped} {
        system Diagonal -lumped
    } else {
        system Diagonal
    }
    test NormUnbalance 1.0e-10 1
    algorithm Linear
    integrator ExplicitDifference
    analysis Transient

    analyze 1 1.0

    set a1 [nodeAccel 1 1]
    set a2 [nodeAccel 2 1]
    return [list $a1 $a2]
}

puts "============================================================"
puts "Consistent truss mass matrix: M_ii = $m_diag, row-sum (lumped) = $m_lumped"
puts "Total physical element mass  = $totalMass"
puts "Applied nodal force (consistent with uniform accel a0=$a0): F = $F"
puts "Expected acceleration under exact mass accounting: a0 = $a0"
puts "============================================================"

set resPlain  [buildModel 0]
set a1p [lindex $resPlain 0]
set a2p [lindex $resPlain 1]
set effMassPlain [expr ($F + $F)/$a1p]

puts "\nsystem Diagonal (no -lumped, off-diagonals dropped):"
puts "  node 1 accel = $a1p   node 2 accel = $a2p   (expected $a0)"
puts "  effective total mass seen by solver = $effMassPlain   (expected $totalMass)"

set resLump [buildModel 1]
set a1l [lindex $resLump 0]
set a2l [lindex $resLump 1]
set effMassLump [expr ($F + $F)/$a1l]

puts "\nsystem Diagonal -lumped (row-sum lumping):"
puts "  node 1 accel = $a1l   node 2 accel = $a2l   (expected $a0)"
puts "  effective total mass seen by solver = $effMassLump   (expected $totalMass)"

puts "\n============================================================"
set tol 1.0e-9
if {abs($a1l-$a0) < $tol && abs($a2l-$a0) < $tol && abs($effMassLump-$totalMass) < $tol} {
    puts "PASS: system Diagonal -lumped conserves total mass and recovers a0=$a0 exactly."
} else {
    puts "FAIL: system Diagonal -lumped did NOT recover the expected result."
}

if {abs($a1p-$a0) < $tol} {
    puts "NOTE: plain system Diagonal unexpectedly also matched a0 (not demonstrating the bug)."
} else {
    puts "CONFIRMED: plain system Diagonal over-predicts acceleration ($a1p vs expected $a0) because it drops the off-diagonal mass terms -> effective mass $effMassPlain instead of $totalMass."
}
