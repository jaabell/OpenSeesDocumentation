.. _SixNodeTri:

tri6n (SixNodeTri) Element
^^^^^^^^^^^^^^^^^^^^^^^^^^

This command constructs a 6-node, quadratic, plane-stress/plane-strain triangular
element with 3-point Gauss integration. The command name in OpenSees is ``tri6n``
(the underlying C++ class is named ``SixNodeTri``, but there is no ``SixNodeTri``
command -- only ``tri6n`` is registered in either interpreter). Use with
``-ndm 2 -ndf 2``.

.. function:: element tri6n $eleTag $iNode $jNode $kNode $lNode $nNode $mNode $thick $type $matTag <$pressure $rho $b1 $b2> <-doInitDisp $flag>

.. csv-table::
   :header: "Argument", "Type", "Description"
   :widths: 10, 10, 40

   $eleTag, |integer|, unique element tag
   $iNode $jNode $kNode, |integer|, the three corner nodes, in counter-clockwise order
   $lNode $nNode $mNode, |integer|, the three mid-edge nodes: $lNode on edge i-j, $nNode on edge j-k, $mNode on edge k-i
   $thick, |float|, element thickness
   $type, |string|, material formulation: ``PlaneStrain`` or ``PlaneStress``
   $matTag, |integer|, tag of an nD material
   $pressure, |float|, surface pressure (optional; default 0.0)
   $rho, |float|, element mass density per unit volume (optional; default 0.0)
   $b1 $b2, |float|, constant body forces in the domain (optional; default 0.0)
   -doInitDisp $flag, |integer|, optional: if $flag is non-zero, strains are measured relative to each node's displacement at the moment the element is added to the domain (default off, $flag = 0)

.. note::

   1. If all optional ``$pressure $rho $b1 $b2`` arguments are supplied, all four must be provided.

   2. ``-doInitDisp $flag`` may follow ``$matTag`` directly, or follow a fully-specified ``$pressure $rho $b1 $b2`` block; both parsers (Tcl and the Python/generic interpreter) accept either position. For example, both of the following are valid:

      .. code-block:: tcl

         element tri6n 1 1 2 3 4 5 6 1.0 PlaneStrain 1 -doInitDisp 1
         element tri6n 1 1 2 3 4 5 6 1.0 PlaneStrain 1 0.0 0.0 0.0 0.0 -doInitDisp 1

   3. **Node ordering.** The element uses standard quadratic (T6) area-coordinate
      shape functions. Corners $iNode, $jNode, $kNode must be given
      counter-clockwise; the mid-edge nodes are $lNode between $iNode and
      $jNode, $nNode between $jNode and $kNode, and $mNode between $kNode and
      $iNode (confirmed from ``SixNodeTri::shapeFunction``, where the
      area-coordinate products :math:`4L_1L_2`, :math:`4L_2L_3`,
      :math:`4L_1L_3` associate with $lNode, $nNode, $mNode respectively).

   4. **Integration.** Strains and stresses are evaluated at 3 interior Gauss
      points (the standard degree-2 triangular quadrature rule, weights
      1/6 each), one ``nDMaterial`` copy per integration point -- unlike
      :ref:`Tri31`, which uses a single centroidal point.

   5. Valid :ref:`elementRecorder` queries include ``forces``, ``stresses``,
      ``stressesAtNodes`` (stresses extrapolated from the 3 Gauss points to
      the 6 nodes), ``strains``, and ``material $matNum ...`` /
      ``integrPoint $matNum ...`` (response of the material at integration
      point $matNum, 1 to 3).

   6. The MPCO recorder (``SRC/recorder/MPCORecorder.cpp``) recognizes
      ``SixNodeTri`` and records it as geometry type ``Triangle_6N`` with the
      3-point Gauss-Legendre integration rule.

   7. **Staged construction.** With the default ``-doInitDisp 0``, strain is
      computed from the raw trial displacement of the element's nodes. When
      ``-doInitDisp 1`` is given, ``SixNodeTri::setDomain()`` captures the
      committed displacement of each of the 6 nodes at the moment the element
      is added to the domain, and strain is thereafter computed from the
      displacement *increment* relative to that captured value -- the same
      mechanism as :ref:`Tri31`'s ``-doInitDisp`` (see that page for the
      worked example; the same ``example_staged_tri.tcl`` logic applies
      equally to ``tri6n``, only the shape functions and integration differ).

.. admonition:: Example

   1. **Tcl Code**

   .. code-block:: tcl

      element tri6n 1 1 2 3 4 5 6 1.0 PlaneStress 1

   2. **Python Code**

   .. code-block:: python

      element('tri6n', 1, 1, 2, 3, 4, 5, 6, 1.0, 'PlaneStress', 1)

   3. **Staged construction with** ``-doInitDisp``

   .. code-block:: tcl

      element tri6n 1 1 2 3 4 5 6 1.0 PlaneStrain 1 -doInitDisp 1

   See :download:`example_staged_tri.tcl` (on the :ref:`Tri31` page) for a
   numerically-checked staged-construction example; it uses ``Tri31`` for
   brevity, but the same ``-doInitDisp`` mechanism, verified against the
   same hand calculation, applies to ``tri6n``.

Code developed by: Seweryn Kokot, Opole University of Technology, Poland
