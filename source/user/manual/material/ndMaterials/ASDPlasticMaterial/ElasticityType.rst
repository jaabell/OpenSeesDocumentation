.. _ElasticityType:

Elasticity Types
^^^^^^^^^^^^^^^^

These components define the stress-strain relationship for the linear part of the model (see :ref:`ASDPlasticTheory`). 

.. math::
   \newcommand{\vec}[1]{\boldsymbol{#1}}
   \vec{\sigma} = \vec{E} \vec{\epsilon}

Where the operator :math:`\vec{E}` may depend on the material state, parameters, etc. 

.. note::
   When using :ref:`ASDPlasticMaterial3D`, elastic parameters can be updated during analysis using the ``setParameter`` command, allowing for simulation of materials with time-dependent or state-dependent elastic properties. This is particularly useful for modeling damage effects, temperature-dependent stiffness, or staged construction processes.


.. _LinearIsotropic3D_EL:

LinearIsotropic3D_EL
""""""""""""""""""""

A classic!

.. math::
   \vec{E}\,=\,{\frac {E}{(1+\nu )(1-2\nu )}}{\begin{bmatrix}1-\nu &\nu &\nu &0&0&0\\\nu &1-\nu &\nu &0&0&0\\\nu &\nu &1-\nu &0&0&0\\0&0&0&{\frac {1-2\nu }{2}}&0&0\\0&0&0&0&{\frac {1-2\nu }{2}}&0\\0&0&0&0&0&{\frac {1-2\nu }{2}}\end{bmatrix}}


.. admonition:: Parameters required

   .. csv-table:: 
      :header: "Parameter name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``YoungsModulus``, scalar, :math:`E`, Young's modulus (Pa or psi)
       ``PoissonsRatio``, scalar, :math:`\nu`, "Poisson's ratio (dimensionless, typically 0.0-0.5)"

.. admonition:: Usage in ASDPlasticMaterial3D

   LinearIsotropic3D_EL provides the fundamental elastic behavior for most engineering materials. With :ref:`ASDPlasticMaterial3D`:
   
   * Constant elastic properties throughout analysis
   * Efficient computation with closed-form tangent
   * Suitable for metals, concrete at small strains, and other linear elastic materials
   
   Monitor elastic behavior:
   
   .. code-block:: tcl
   
       # Update elastic parameters during analysis (assuming material tag 1
       # is attached to element 1)
       setParameter -value 3e10 -ele 1 YoungsModulus
       setParameter -value 0.2 -ele 1 PoissonsRatio

.. _DuncanChang_EL:

DuncanChang_EL
""""""""""""""

This is a hypoelastic model that features pressure dependent behavior. It is composed of an isotropic elastic model where the Young's modulus has the following dependency on the maximum principal stress :math:`\sigma_3` (it is assumed that :math:`\sigma_1 \leq \sigma_2 \leq \sigma_3 < 0`).

.. math::
   E(\sigma_3) = E_{ref} \cdot p_{ref} \cdot \left(\dfrac{\vert \sigma_3 \vert}{ p_{ref}} \right)^n

Where :math:`E_{ref}` (dimensionless) specifies the Young's modulus at reference pressure :math:`p_{ref}` and :math:`n` is a material constant. A cut-off maximum confinement pressure :math:`\sigma_{3max}` at which the Young's modulus will be evaluated should the confinement be greater than that value. 

.. admonition:: Parameters required

   .. csv-table:: 
      :header: "Parameter name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``ReferenceYoungsModulus``, scalar, :math:`E_{ref}`, Dimensionless reference Young's modulus at reference pressure :math:`p_{ref}`.
       ``PoissonsRatio``, scalar, :math:`\nu`, Poisson's ratio (dimensionless)
       ``ReferencePressure``, scalar, :math:`p_{ref}`, Reference pressure for the definition of Young's modulus (Pa).
       ``DuncanChang_MaxSigma3``, scalar, :math:`\sigma_{3max}`, Maximum confinement stress (Pa).
       ``DuncanChang_n``, scalar, :math:`n`, Exponent for Duncan-Chang law (typically 0.2-1.0).

.. admonition:: Usage in ASDPlasticMaterial3D

   DuncanChang_EL provides pressure-dependent elastic behavior, particularly useful for:
   
   * Soil materials with stiffness increasing with confinement
   * Rock materials exhibiting non-linear elastic response
   * Interfaces and joints with pressure-dependent behavior
   
   The Young's modulus varies with minimum principal stress :math:`\sigma_3` (compression negative):
   
   .. math::
      E(\sigma_3) = E_{ref} \cdot p_{ref} \cdot \left(\dfrac{\vert \sigma_3 \vert}{ p_{ref}} \right)^n
   
   Monitor pressure-dependent response (assuming material tag 1 is attached
   to element 1):

   .. code-block:: tcl

       recorder Element -ele 1 -file pressure.out -time material 1 PStress
       recorder Element -ele 1 -file j2_stress.out -time material 1 J2Stress

``DuncanChang_EL`` is compiled against every "standard" yield function / plastic flow direction combination (the same set that ``LinearIsotropic3D_EL`` is available for), not just a specific subset. Its parameters use dedicated names (``ReferenceYoungsModulus``, ``ReferencePressure``) that no longer collide with ``LinearIsotropic3D_EL``'s ``YoungsModulus``/``PoissonsRatio``-only convention.


.. _StiffSoil_EL:

StiffSoil_EL
""""""""""""

Stress-dependent elasticity for the unloading/reloading branch of the Hardening-Soil model (PLAXIS Eq. 15.3), used together with either :ref:`StiffSoilShear_YF`/:ref:`StiffSoilShear_PF` or :ref:`StiffSoilCap_YF`/:ref:`StiffSoilCap_PF`. It is otherwise an isotropic elastic law, but the Young's modulus depends on the current minor principal (confining) stress :math:`\sigma_3`:

.. math::
   E_{ur}(\sigma_3) = E_{ur}^{ref}\left(\dfrac{c\cos\varphi + \sigma_3\sin\varphi}{c\cos\varphi + p_{ref}\sin\varphi}\right)^m

:math:`\sigma_3` is clamped to a minimum of :math:`0.1\,p_{ref}` to avoid zero or negative stiffness as the confinement approaches zero or becomes tensile, and the resulting :math:`E_{ur}` is further floored at :math:`0.01\,E_{ur}^{ref}`.

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``SS_Eur_ref``, scalar, :math:`E_{ur}^{ref}`, Unload/reload Young's modulus at the reference pressure :math:`p_{ref}`.
       ``PoissonsRatio``, scalar, :math:`\nu`, Poisson's ratio for the unload/reload response (typically around 0.2).
       ``SS_pref``, scalar, :math:`p_{ref}`, Reference pressure.
       ``SS_m``, scalar, :math:`m`, Power exponent (typically 0.5-1.0).
       ``MC_phi``, scalar, :math:`\varphi`, "Friction angle (degrees), shared with the paired yield function/plastic flow direction."
       ``MC_c``, scalar, :math:`c`, "Cohesion, shared with the paired yield function/plastic flow direction."

.. admonition:: Usage in ASDPlasticMaterial3D

   ``StiffSoil_EL`` is only compiled together with the dedicated ``StiffSoilShear_*``/``StiffSoilCap_*`` components (see ``gen_ASD_material_definitions_CPP.py``); it is not available with the other, "standard" yield functions. Each of the shear and cap mechanisms is a **separate** ``ASDPlasticMaterial3D`` instance (there is no single instance combining both), so ``StiffSoil_EL``'s stress-dependent stiffness is evaluated using whatever confining stress that particular instance currently has.

