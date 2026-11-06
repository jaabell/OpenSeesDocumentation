.. _SplitElastic:

SplitElastic Element
^^^^^^^^^^^^^^^^^^^^

``SplitElastic`` contains two coincident, half-property, small-strain isotropic
elastic continua in one four-node quadrilateral (2-D) or eight-node brick (3-D).
It is intended for a finite split absorbing exterior, with complementary free
and fixed branch ends and optional passive relative-velocity damping.

.. function:: element('SplitElastic', eleTag, *eleNodes, E, nu, rho, <'-thickness', t>, <'-planeStrain'|'-planeStress'>, <'-lMass'|'-cMass'>, <'-coupling', eta>, <'-couplingFactors', *factors>)

The Tcl command has the same argument order, without Python punctuation.
The model dimension selects four or eight node tags. Standard ``quad`` and
``stdBrick`` connectivity orders apply; all integration-point Jacobians must
be positive. Full 2x2 or 2x2x2 Gauss integration is used.

* ``E``, ``nu``, ``rho`` are the **full parent-medium** Young's modulus,
  Poisson ratio and density. Each branch has half of its stiffness and mass.
  Require finite ``E > 0``, ``-1 < nu < 0.5`` and ``rho >= 0``. Properties
  may vary between elements; interface properties must match the local medium.
* ``-thickness t`` is 2-D only, defaults to 1, and requires ``t > 0``.
* The 2-D default is ``-planeStrain``; ``-planeStress`` is optional.
* ``-lMass`` (default) uses row-summed lumped mass. ``-cMass`` uses consistent
  mass. Both branches use the selected mass convention.
* ``-coupling eta`` supplies a nonnegative relative-velocity damping coefficient
  per physical volume (default zero). In 2-D, volume includes thickness.
* ``-couplingFactors`` supplies one nonnegative multiplier per element node,
  in connectivity order (default all one). At node ``i``, this element contributes
  ``c_i = eta * factor_i * integral(N_i dV)``. Adjacent contributions add.
  Thus a prescribed nodal taper can reproduce a separately assembled viscous
  connector exactly. The coefficient is **not halved** with branch properties.

Node DOFs and terminal constraints
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The element inspects each node's actual number of DOFs, independent of the
current model builder setting:

* A 2-D node with 2 DOFs or a 3-D node with 3 DOFs is a shared physical node.
  Both branches assemble into these same translations. Such nodes connect
  directly to ordinary interior elements, without interface ``equalDOF`` ties.
* A 2-D node with 4 DOFs or a 3-D node with 6 DOFs has independent branch
  translations. DOFs ``1..ndm`` belong to branch 1; DOFs ``ndm+1..2*ndm``
  belong to branch 2. **The additional DOFs are translations, not rotations.**
* Other DOF counts are rejected. Do not mix ordinary rotational elements with
  paired exterior nodes. There are no automatic boundary constraints.

Create ordinary nodes first with ``model BasicBuilder -ndm 3 -ndf 3``, then
switch to ``-ndf 6`` for paired exterior nodes. At the outer surface use::

    fix $nodeTag 1 1 1 0 0 0

This fixes branch 1 and leaves branch 2 free. The 2-D counterpart is::

    fix $nodeTag 1 1 0 0

The same physical exterior mesh carries both branches. At shared nodes there
is no relative damping because both branch velocities are identical. With all
nodes shared, the element reduces to the full-property parent elastic solid.
Complementary cancellation is a one-dimensional linear-wave result; finite
multidimensional corner paths need separate validation. This is a finite
exterior, not a permanently reflection-free boundary.

Damping and integration
~~~~~~~~~~~~~~~~~~~~~~~

The internal connector produces opposite forces ``c_i*(v1-v2)`` on the two
branches. Its dissipated power is ``sum(c_i*|v1-v2|^2) >= 0``. Common branch
motion is an exact null mode. It modifies later relative branch motion rather
than replacing the incident-wave impedance.

Ordinary ``rayleigh`` and ``region ... -rayleigh`` commands add damping to
each half-property branch. These commands do not remove the internal connector.
The elastic stiffness and mass are cached; ``update`` has no constitutive work.
Current, initial and committed stiffness Rayleigh terms are identical here.

``ExplicitDifference`` with a diagonal SOE requires the default lumped mass.
In upstream OpenSees, ``Diagonal``/``MPIDiagonal`` extract the diagonal of a
supplied matrix; they do not row-sum a consistent mass. Using ``-cMass`` with
such a system loses mass. Use a full-matrix solver for consistent-mass analyses,
or an SOE whose row-summing behavior has been independently verified.

Relative damping adds its own explicit stability restriction. For an isolated
rigid differential mode with lumped branch mass ``rho*V_i/2``, its decay rate is
``4*eta*factor_i/rho``. ``ExplicitDifference`` therefore requires
``dt < rho/(2*eta*factor_i)`` for that mode. This is a necessary damping-only
bound, not a sufficient bound for the complete mesh: stiffness, constraints
and Rayleigh damping may require a smaller time step. Check stability in
addition to the elastic wave Courant limit.

Nodal forces are supported. Element body/pressure loads are not supported.
Translational ``UniformExcitation`` directions ``1..ndm`` are supported: the
physical ground-acceleration influence in the first translation set is used
for **both** branches. Do not issue additional excitation patterns for DOFs
``ndm+1..2*ndm``; upstream interprets those directions as rotations, which this
element does not support. Independently prescribed branch motions should use
explicit SP constraints rather than ``UniformExcitation``.

Recorders
~~~~~~~~~

* ``forces``: elastic resisting force minus applied element inertia loads, in
  concatenated node-DOF order; does not include trial damping or inertia forces.
* ``stresses1``, ``stresses2``: actual half-property branch stresses at Gauss
  points. ``stresses`` is their sum, the full-property common-mode resultant.
* ``strains1``, ``strains2``: branch engineering strains. ``strains`` is their mean.
  Components are ``xx yy xy`` in 2-D and ``xx yy zz xy yz zx`` in 3-D.
  Gauss-point order follows the connectivity sign order.
* ``energy``: elastic strain energy, kinetic energy, instantaneous internal
  relative-damping power. The last entry is power, not integrated dissipated energy.
* ``relativePower``: the same instantaneous nonnegative connector power alone.
* ``stiffness``, ``mass``, ``damping``: flattened row-major element matrices,
  primarily for small-model verification. ``damping`` includes Rayleigh damping.

Text node recorders must specify the required branch DOFs explicitly.
Visualization recorders may interpret DOFs 4--6 as rotations and need a
branch-aware adapter; ordinary model-domain node output remains conventional.
Database save/restore is supported. This command has fixed elastic properties;
a nonlinear variant would require independent constitutive histories in each
branch, and would need its own validation. Linear cancellation is not a proof
of cancellation in a nonlinear medium.

Example (3-D)
~~~~~~~~~~~~~

.. code-block:: tcl

    model BasicBuilder -ndm 3 -ndf 3
    node 1 0 0 0
    node 4 0 1 0
    node 5 0 0 1
    node 8 0 1 1
    model BasicBuilder -ndm 3 -ndf 6
    node 2 1 0 0
    node 3 1 1 0
    node 6 1 0 1
    node 7 1 1 1
    element SplitElastic 1 1 2 3 4 5 6 7 8 1000.0 0.25 2.0 -coupling 10.0 -couplingFactors 1 0 0 1 1 0 0 1
    foreach n {2 3 6 7} { fix $n 1 1 1 0 0 0 }
    # Connect ordinary elastic interior elements to nodes 1,4,5,8.

Independent operator, passivity, patch, transient and database checks are
provided in ``tests/test_split_elastic.py`` in the OpenSees source repository.

Code developed by Jose Antonio Abell.
