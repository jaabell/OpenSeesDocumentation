.. _Tri31:

Tri31 Element
^^^^^^^^^^^^^

This command constructs a constant-strain triangular element using three nodes and one integration point. The command name in OpenSees is ``Tri31`` or ``tri31``. Use with ``-ndm 2 -ndf 2``.

.. function:: element Tri31 $eleTag $iNode $jNode $kNode $thick $type $matTag <$pressure $rho $b1 $b2> <-doInitDisp $flag>

.. csv-table::
   :header: "Argument", "Type", "Description"
   :widths: 10, 10, 40

   $eleTag, |integer|, unique element tag
   $iNode $jNode $kNode, |integer|, three nodes in counter-clockwise order
   $thick, |float|, element thickness
   $type, |string|, material formulation: ``PlaneStrain`` or ``PlaneStress``
   $matTag, |integer|, tag of an nD material
   $pressure, |float|, surface pressure (optional; default 0.0)
   $rho, |float|, element mass density per unit volume (optional; default 0.0)
   $b1 $b2, |float|, constant body forces in the domain (optional; default 0.0)
   -doInitDisp $flag, |integer|, optional: if $flag is non-zero, strains are measured relative to each node's displacement at the moment the element is added to the domain (default off, $flag = 0)

.. note::

   1. If all optional arguments are supplied, all four must be provided.

   2. Consistent nodal loads are computed from pressure and body forces.

   3. Valid :ref:`elementRecorder` queries include ``forces``, ``stresses``, and ``material $matNum ...``.

   4. ``-doInitDisp $flag`` may follow ``$matTag`` directly, or follow a fully-specified ``$pressure $rho $b1 $b2`` block; it cannot be combined with a partially-specified optional block. For example, both of the following are valid:

      .. code-block:: tcl

         element Tri31 1 1 2 3 1.0 PlaneStrain 1 -doInitDisp 1
         element Tri31 1 1 2 3 1.0 PlaneStrain 1 0.0 0.0 0.0 0.0 -doInitDisp 1

   5. **Staged construction.** With the default ``-doInitDisp 0``, strain is computed from the raw trial displacement of the element's nodes. When ``-doInitDisp 1`` is given, ``Tri31::setDomain()`` captures the committed displacement of each node at the moment the element is added to the domain, and strain is thereafter computed from the displacement *increment* relative to that captured value. This lets a new "layer" of elements be added onto an already-deformed mesh (e.g. fill, lining, or a new construction stage) without inheriting the pre-existing displacement of its nodes as spurious strain. See the worked example below.

.. admonition:: Example

   1. **Tcl Code**

   .. code-block:: tcl

      element Tri31 1 1 2 3 1.0 PlaneStress 1

   2. **Python Code**

   .. code-block:: python

      element('Tri31', 1, 1, 2, 3, 1.0, 'PlaneStress', 1)

.. admonition:: Example -- staged construction with ``-doInitDisp``

   :download:`example_staged_tri.tcl` builds a one-layer mesh of two ``Tri31`` elements, shears it (prescribed :math:`u_x = 0.01` on the top edge), then adds a second layer of ``Tri31`` elements onto the deformed top edge, with and without ``-doInitDisp``. For an isotropic-elastic material with :math:`E = 1000`, :math:`\nu = 0`, the shear stress is :math:`\sigma_{xy} = \frac{E}{2}\gamma_{xy}`. Hand calculation and the script's printed got-vs-expected values (run with the ``ladruño`` build):

   - Layer 1 (sheared): :math:`\gamma_{xy} = 0.01 \Rightarrow \sigma_{xy} = 5.0` -- got ``4.99999999994999910768``.
   - Layer 2, no ``-doInitDisp`` (inherits the layer-1 shear of the shared nodes): expected :math:`\sigma_{xy} = -5.0` -- got ``-5.00000000006250022722`` and ``-5.00000000003750066924``.
   - Layer 2, ``-doInitDisp 1`` (strain measured relative to the displacement at the moment the element was added): expected :math:`\sigma_{xy} = 0.0` -- got ``-0.00000000003750041737`` and ``-0.00000000001250041737``.

Code developed by: Roozbeh G. Mikola, N. Sitar
