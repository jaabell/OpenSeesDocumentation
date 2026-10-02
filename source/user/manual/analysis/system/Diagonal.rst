Diagonal & MPIDiagonal System
-----------------------------

This command is used to construct a Diagonal linear system of equation object. This system stores only the diagonal entries of the coefficient matrix, making it extremely memory efficient for problems where off-diagonal coupling can be neglected or lumped into the diagonal. The system is solved by direct inversion of the diagonal entries. The following command is used to construct such a system:

.. function:: system (Diagonal|MPIDiagonal) <-lumped>

   **Optional Parameter:**

   * **-lumped** (also accepted without the leading dash, as **lumped**) - If specified, off-diagonal matrix entries are added (lumped) to the diagonal before solving. This is useful for mass matrix lumping or when converting a coupled system to a diagonal approximation. Default: off (off-diagonal entries are dropped, not lumped). The token is only recognized if it immediately follows the ``Diagonal``/``MPIDiagonal`` keyword; both the Tcl and Python/OpenSeesPy interpreters parse it the same way.

.. note::

   **OpenSeesSP limitation.** In an OpenSeesSP build (compiled with ``_PARALLEL_PROCESSING``), ``system Diagonal`` is built on top of ``DistributedDiagonalSOE``/``DistributedDiagonalSolver`` instead of the serial ``DiagonalSOE``/``DiagonalDirectSolver`` pair, and that distributed pair has no lumping option at all: the ``-lumped``/``lumped`` token is silently ignored in that configuration. ``system MPIDiagonal`` is not affected -- it always uses ``MPIDiagonalSOE`` (when built with ``_PARALLEL_INTERPRETERS``) or the serial ``DiagonalSOE``, both of which honor ``-lumped``.

A diagonal system stores only the diagonal entries of an n×n matrix **A**, where:

:math:`K = \begin{bmatrix} k_{11} & 0 & \cdots & 0 \\ 0 & k_{22} & \cdots & 0 \\ \vdots & \vdots & \ddots & \vdots \\ 0 & 0 & \cdots & k_{nn} \end{bmatrix}`

The solution for :math:`K u = f` is obtained directly as:

:math:`u_i = \frac{f_i}{k_{ii}} \quad \text{for } i = 1, \ldots, n`

.. note::

   1. This solver requires that all diagonal entries are non-zero.
   2. The system only stores n values instead of n² for a full matrix, providing significant memory savings
   3. When using the **-lumped** option, the solver accumulates all off-diagonal entries in each row/column into the corresponding diagonal entry

Mass Lumping
^^^^^^^^^^^^

When the **-lumped** option is specified, the Diagonal or MPIDiagonal system performs **mass lumping** (also called diagonal lumping or row-sum lumping). This technique converts a consistent (coupled) mass matrix into a diagonal form by summing all entries in each row and placing the total on the diagonal.

**Mathematical Formulation:**

For a consistent mass matrix **M** with entries :math:`m_{ij}`, the lumped diagonal entry is:

:math:`\tilde{m}_{ii} = \sum_{j=1}^{n} m_{ij}`

All off-diagonal entries are set to zero: :math:`\tilde{m}_{ij} = 0` for :math:`i \neq j`

.. warning::

   1. This system is only appropriate when the problem structure allows diagonal treatment
   2. Mass lumping is generally only recommended for the mass matrix in dynamic analysis (ExplicitDifference integrator or CentralDifference integrator if no damping matrix is used or only mass proportional Rayleigh damping is used)
   3. Lumping the stiffness matrix is rarely appropriate and can lead to poor results
   4. For static analysis or implicit dynamics use full sparse solvers.
   5. Ideally, lumping should be handled at the element level, especially for high-order elements (like the TenNodeTetrahedron or SixNodeTriangle) where this technique leads to negative mass values (!!). 

**Implementation Details:**

When **-lumped** is specified:

.. code-block:: none

   For each element matrix entry m(i,j) at DOF locations id(i), id(j):
      A[id(i)] += m(i,i)           // Add diagonal entry
      if (lumped):
         for all j ≠ i:
            A[id(i)] += m(j,i)     // Add all column entries to diagonal

This ensures that the total contribution from each element is preserved while creating a diagonal system.


.. admonition:: Example 

   The following examples show how to construct a Diagonal system

   **1. Tcl Code - Basic diagonal system (no lumping)**

   .. code-block:: tcl

      system Diagonal

   **2. Tcl Code - Diagonal system with mass lumping for explicit dynamics**

   .. code-block:: tcl

      # Explicit dynamic analysis with lumped mass
      system Diagonal -lumped
      ;# equivalently:  system Diagonal lumped

      constraints Plain
      numberer Plain
      test NormDispIncr 1.0e-6 10 0
      algorithm Linear
      integrator CentralDifference
      analysis Transient

   **2b. Tcl Code - MPIDiagonal with mass lumping (OpenSeesMP / MPIDiagonal builds)**

   .. code-block:: tcl

      system MPIDiagonal -lumped

   **3. Python Code - Basic diagonal system**

   .. code-block:: python

      ops.system('Diagonal')

   **4. Python Code - Lumped mass for explicit analysis**

   .. code-block:: python

      # Setup for explicit central difference method
      ops.system('Diagonal', '-lumped')
      ops.constraints('Plain')
      ops.numberer('Plain')
      ops.integrator('CentralDifference')
      ops.analysis('Transient')

      # 'MPIDiagonal' accepts the same '-lumped'/'lumped' flag in OpenSeesPy
      ops.system('MPIDiagonal', '-lumped')

   **5. Python Code - Complete explicit dynamics example**

   .. code-block:: python

      import openseespy.opensees as ops
      
      # ... model definition ...
      
      # Analysis setup for blast/impact with lumped mass
      ops.system('Diagonal', '-lumped')
      ops.constraints('Plain')
      ops.numberer('Plain')
      ops.test('NormDispIncr', 1.0e-6, 10, 0)
      ops.algorithm('Linear')
      ops.integrator('CentralDifference')
      ops.analysis('Transient')
      
      # Time step (must satisfy CFL condition)
      dt = 0.0001
      ops.analyze(1000, dt)

.. admonition:: Worked example - ``-lumped`` recovers the correct total mass

   A single 1-D ``Truss`` element (2 nodes, 1 DOF each, length :math:`L=1`,
   area :math:`A=1`, density :math:`\rho = 6`) is built with a *consistent*
   mass matrix (``-cMass 1``):

   :math:`M = \frac{\rho A L}{6}\begin{bmatrix} 2 & 1 \\ 1 & 2 \end{bmatrix} = \begin{bmatrix} 2 & 1 \\ 1 & 2 \end{bmatrix}`

   A constant nodal force :math:`F = 6` is applied at both nodes (the force
   that a uniform acceleration :math:`a_0 = 2` produces through the
   row-summed/lumped mass, :math:`F = \tfrac{\rho A L}{2}\, a_0`), and a
   single step of ``integrator ExplicitDifference`` is taken from rest, so
   that the analysis solves :math:`M a = F` through whichever ``system
   Diagonal`` variant is active:

   * ``system Diagonal`` (no ``-lumped``): only the diagonal entries of
     :math:`M` are kept (:math:`A_{ii} = M_{ii} = 2`), so the solver only
     "sees" :math:`2\times 2 = 4` of the physical total mass
     :math:`\rho A L = 6`. The computed acceleration is
     :math:`a = F / M_{ii} = 6/2 = 3`, 50% higher than the correct value.
   * ``system Diagonal -lumped``: the off-diagonal entries are folded onto
     the diagonal (:math:`A_{ii} = 2 + 1 = 3`, the full row sum), so the
     solver sees the whole physical mass (:math:`2 \times 3 = 6`) and
     recovers :math:`a = F / 3 = 2`, matching :math:`a_0` exactly.

   :download:`example_lumped_explicit.tcl` builds and solves both cases and
   checks the result:

   .. code-block:: text

      system Diagonal (no -lumped, off-diagonals dropped):
        node 1 accel = 3.0   node 2 accel = 3.0   (expected 2.0)
        effective total mass seen by solver = 4.0   (expected 6.0)

      system Diagonal -lumped (row-sum lumping):
        node 1 accel = 2.0   node 2 accel = 2.0   (expected 2.0)
        effective total mass seen by solver = 6.0   (expected 6.0)

      PASS: system Diagonal -lumped conserves total mass and recovers a0=2.0 exactly.

   Run with ``OpenSees example_lumped_explicit.tcl``; the printed values above
   were produced by that exact script.

Code Developed by: |fmk|


