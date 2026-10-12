.. _`YieldFunctionType`:

Yield Functions
^^^^^^^^^^^^^^^

Specifies the shape of the yield surface, i.e. locus of points in stress-space where the response of the material is linear. Points outside of yield surface are not allowed. Yield surfaces can have parameters and internal variables which define its shape and location. 

Yield Functions may define internal variables they need for their specification, as well as paramters. When specifying ``ASDPlasticMaterial`` or ``ASDPlasticMaterial3D`` instance, one must provide internal variables mentioned below, together with their hardening function. 

Yield functions are also responsible for providing their stress-derivative (:math:`\mathbf{n} = \partial f / \partial \boldsymbol{\sigma}`) as well as computing hardening term :math:`H` in the plastic multiplier (see :ref:`ASDPlasticTheory`). 

.. note::
   When using :ref:`ASDPlasticMaterial3D`, yield function internal variables can be accessed directly using enhanced response queries. This provides detailed insight into material state evolution during analysis.

Available functions:


.. _VonMises_YF:

VonMises_YF
"""""""""""

Defines a yield surface which corresponds to the `Von Mises Yield Criterion <https://en.wikipedia.org/wiki/Von_Mises_yield_criterion>`_. Its definition is:

.. math::
   \newcommand{\vec}[1]{\boldsymbol{#1}}
   \newcommand{\state}{\sigma, \left\lbrace iv \right\rbrace, \left\lbrace param \right\rbrace }
   \newcommand{\matorvec}[2]{
    \left[\begin{array}{#1}
        #2
    \end{array}\right]
    }
   f(\vec{\sigma}) = \sqrt{ (\vec{s} - \vec{\alpha}) \cdot (\vec{s} - \vec{\alpha}) } - \sqrt{ \dfrac{2}{3}} k

   \vec{s} = \vec{\sigma} - p \vec{I}

Where :math:`p = -(\sigma_{11} + \sigma_{22} + \sigma_{33})/3` is the mean stress (positive in compression), and :math:`\vec{I}` is the Kronecker delta in Voigt notation (:math:`\vec{I} = \matorvec{cccccc}{1 & 1 & 1 & 0 & 0 & 0}^T`). Finally, :math:`\vec{s}` is the deviatoric part of the stress vector in Voigt notation. 

.. admonition:: Internal variables defined

   .. csv-table:: 
      :header: "IV Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``BackStress``, Rank-6 Tensor , :math:`\vec{\alpha}`,  "Backstress, definining the location in stress space for the axis of the Von-Mises cylinder. "
      ``YieldStress``, Scalar , :math:`k`,  "Shear strength, definining the radius of the Von-Mises cylinder in stress space. "

.. admonition:: Parameters required

   None required for the yield function itself. Parameters are defined by the internal variable hardening functions and elasticity model.

.. admonition:: Usage in ASDPlasticMaterial3D

   When using VonMises_YF with :ref:`ASDPlasticMaterial3D`, you can access the internal variables using enhanced response queries:

   * ``YieldStress`` - Current radius of the yield surface
   * ``BackStress`` - Current backstress tensor (6 components in Voigt notation)

   These can be recorded using (assuming material tag 1 is attached to element 1):

   .. code-block:: tcl

       recorder Element -ele 1 -file yieldstress.out -time material 1 YieldStress
       recorder Element -ele 1 -file backstress.out -time material 1 BackStress


.. _DruckerPrager_YF:

DruckerPrager_YF
""""""""""""""""


Defines a yield surface related to the `Drucker-Prager Yield Criterion <https://en.wikipedia.org/wiki/Drucker%E2%80%93Prager_yield_criterion>`_. Its actual implementation is:

.. math::
   f(\vec{\sigma}) = \sqrt{ \dfrac{1}{2}(\vec{s} - \vec{\alpha}) \cdot (\vec{s} - \vec{\alpha}) } + \eta\, p - \xi_c

where :math:`p` is the mean stress (positive in compression) and :math:`\eta`, :math:`\xi_c` are **parameters** (not internal variables): :math:`\eta` is the friction slope and :math:`\xi_c` the (adjusted) cohesion intercept. A second internal variable, registered under the name ``DP_cohesion``, is required alongside ``BackStress`` (for consistency with the hardening-function machinery and with :ref:`DruckerPrager_PF`), but its current *value* does not itself appear in :math:`f` above -- only its hardening rate enters the plastic-consistency condition. In practice, set its hardening parameter to zero (as in the verified example below) unless you specifically want this secondary hardening effect.

.. admonition:: Internal variables defined

   .. csv-table::
      :header: "IV Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``BackStress``, Rank-6 Tensor , :math:`\vec{\alpha}`,  "Backstress, definining the location in stress space for the axis of the Drucker-Prager cone. "
      ``DP_cohesion``, Scalar , --,  "Secondary cohesion-like internal variable; see note above."

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``DP_xi_c``, Scalar, :math:`\xi_c`, "Cohesion intercept."
      ``DP_eta``, Scalar, :math:`\eta`, "Friction slope (controls the opening of the cone with respect to the mean stress :math:`p`)."

.. admonition:: Usage in ASDPlasticMaterial3D

   DruckerPrager_YF with :ref:`ASDPlasticMaterial3D` provides access to:

   * ``DP_cohesion`` - Current value of the secondary cohesion-like internal variable
   * ``BackStress`` - Current backstress tensor

   Enhanced stress measures are particularly useful (assuming material tag 1 is attached to element 1):

   .. code-block:: tcl

       recorder Element -ele 1 -file p_stress.out -time material 1 PStress
       recorder Element -ele 1 -file j2_stress.out -time material 1 J2Stress

.. note::

   ``CHECK_APEX_REGION``/``APEX_STRESS`` for this yield function are stubs in the current code (always ``false``/zero): apex handling at the cone's vertex is not yet implemented.


.. _MohrCoulomb_YF:

MohrCoulomb_YF
"""""""""""""""

A smooth, Lode-angle-dependent approximation of the `Mohr-Coulomb Yield Criterion <https://en.wikipedia.org/wiki/Mohr%E2%80%93Coulomb_theory>`_, written directly in terms of the stress invariants :math:`I_1`, :math:`J_2` and the Lode angle :math:`\theta`:

.. math::
   f(\vec{\sigma}) = \left(\cos\theta - \dfrac{\sin\theta\sin\varphi}{\sqrt{3}}\right)\sqrt{J_2} + \dfrac{I_1 \sin\varphi}{3} - c\cos\varphi

This reduces exactly to the classical Mohr-Coulomb criterion on the triaxial meridians (:math:`\theta=\pm30^\circ`); the unconfined compressive strength at :math:`\sigma_3=0` is :math:`\sigma_{ucs}=2c\cos\varphi/(1-\sin\varphi)`, used to verify this component below. ``YIELD_FUNCTION_HARDENING`` is not implemented separately: this yield function is perfectly-plastic (no internal hardening state beyond the usual unused ``BackStress`` placeholder).

.. admonition:: Internal variables defined

   Like :ref:`HoekBrown_YF`, only the unused ``BackStress(NullHardeningTensorFunction)`` placeholder is required.

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``MC_phi``, Scalar, :math:`\varphi`, "Friction angle (degrees)."
      ``MC_c``, Scalar, :math:`c`, "Cohesion."
      ``MC_ds``, Scalar, --, "Relative stress perturbation for the numerical stress-derivative of the yield function."

.. admonition:: Usage in ASDPlasticMaterial3D

   Pair with :ref:`MohrCoulomb_PF` and either :ref:`LinearIsotropic3D_EL` or :ref:`DuncanChang_EL`. Verified with an unconfined-compression example (:download:`../ASDPlasticMaterial3D_MohrCoulombExample.tcl`, see :ref:`ASDPlasticMaterial3D`): got peak axial stress :math:`3.4645\times10^4` Pa vs. expected :math:`2c\cos\varphi/(1-\sin\varphi) = 3.4641\times10^4` Pa (0.01% relative error), with :math:`\varphi=30^\circ`, :math:`c=10` kPa.

   .. code-block:: tcl

       recorder Element -ele 1 -file p_stress.out -time material 1 PStress
       recorder Element -ele 1 -file j2_stress.out -time material 1 J2Stress


.. _HoekBrown_YF:

HoekBrown_YF
""""""""""""

Defines the generalized `Hoek-Brown failure criterion <https://en.wikipedia.org/wiki/Hoek%E2%80%93Brown_failure_criterion>`_ for rock masses, following Hoek, E. and Brown, E.T. (2018), "The Hoek-Brown failure criterion and GSI – 2018 edition", *Journal of Rock Mechanics and Geotechnical Engineering*. Stresses use the geomechanics (compression-positive) convention internally, with :math:`\sigma_1 \geq \sigma_2 \geq \sigma_3` the sorted principal stresses:

.. math::
   \sigma_1 = \sigma_3 + \sigma_{ci}\left(m_b \dfrac{\sigma_3}{\sigma_{ci}} + s\right)^a

The implemented yield function combines this shear-failure surface with a Rankine-style tension cut-off on :math:`\sigma_3`, so that the material also yields in tension beyond the rock mass tensile strength :math:`\sigma_t = -s\,\sigma_{ci}/m_b`:

.. math::
   f(\vec{\sigma}) = \max\Big(\sigma_1 - \sigma_3 - \sigma_{ci}\left(\max(m_b \sigma_3/\sigma_{ci} + s,\, 0)\right)^a,\ \ \sigma_t - \sigma_3 \Big)

The rock-mass parameters :math:`m_b`, :math:`s` and :math:`a` are, by default, derived from the intact-rock material constant :math:`m_i`, the Geological Strength Index :math:`GSI` and the disturbance factor :math:`D`:

.. math::
   m_b = m_i \exp\left(\dfrac{GSI-100}{28-14D}\right) \qquad
   s = \exp\left(\dfrac{GSI-100}{9-3D}\right) \qquad
   a = \dfrac{1}{2} + \dfrac{1}{6}\left(e^{-GSI/15} - e^{-20/3}\right)

Setting ``HB_mb``, ``HB_s`` and/or ``HB_a`` to a value greater than zero overrides the corresponding derived quantity (the override check is simply "> 0", so these three parameters cannot be used to force a value of exactly zero). For intact rock (:math:`GSI=100`, :math:`D=0`) the derived values reduce to :math:`m_b=m_i`, :math:`s=1`, :math:`a=0.5`, and the rock-mass unconfined compressive strength is :math:`\sigma_{cm} = \sigma_{ci}\,s^a`.

The stress-derivative of the yield function is computed purely numerically (central differences with perturbation ``HB_ds``, scaled by the stress norm), rather than analytically.

.. admonition:: Internal variables defined

   ``HoekBrown_YF`` does not use a genuine internal variable (it is a perfectly-plastic criterion with no hardening: ``YIELD_FUNCTION_HARDENING`` always returns zero). It still requires a placeholder ``BackStress`` entry (with a null, i.e. non-hardening, hardening function) for the internal-variable storage mechanism, which :ref:`HoekBrown_PF` also happens to require, so the two collapse into a single internal variable:

   .. csv-table::
      :header: "IV Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``BackStress``, Rank-6 Tensor, :math:`\vec{\alpha}`, "Unused placeholder, always zero. Must be paired with the ``NullHardeningTensorFunction`` hardening function (see :ref:`HardeningFunctions`)."

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``HB_sigci``, scalar, :math:`\sigma_{ci}`, "Unconfined compressive strength of the intact rock (stress units)."
      ``HB_GSI``, scalar, :math:`GSI`, "Geological Strength Index, 0-100."
      ``HB_mi``, scalar, :math:`m_i`, "Intact-rock material constant (typically 4-35, see Hoek & Brown 2018 for rock-type tables)."
      ``HB_D``, scalar, :math:`D`, "Disturbance factor, 0 (undisturbed) to 1 (heavily disturbed)."
      ``HB_mb``, scalar, :math:`m_b`, "Optional direct override for the derived :math:`m_b`; only used if :math:`> 0`."
      ``HB_s``, scalar, :math:`s`, "Optional direct override for the derived :math:`s`; only used if :math:`> 0`."
      ``HB_a``, scalar, :math:`a`, "Optional direct override for the derived :math:`a`; only used if :math:`> 0`."
      ``HB_ds``, scalar, --, "Relative stress perturbation used for the numerical stress-derivative of the yield function."

.. admonition:: Usage in ASDPlasticMaterial3D

   ``HoekBrown_YF`` is intended to be paired with :ref:`HoekBrown_PF` (non-associated flow), and can be used with either :ref:`LinearIsotropic3D_EL` or :ref:`DuncanChang_EL`. List all compiled combinations with:

   .. code-block:: tcl

       nDMaterial ASDPlasticMaterial3D 1 list HoekBrown_YF

   See the worked unconfined-compression example on the :ref:`ASDPlasticMaterial3D` page.

.. _StiffSoilShear_YF:

StiffSoilShear_YF
"""""""""""""""""

Defines the deviatoric (shear) hardening mechanism of the Hardening-Soil model (as in PLAXIS), implemented as one of the two yield surfaces making up the ``StiffSoil`` family of ``ASDPlasticMaterial3D`` components (see also :ref:`StiffSoilCap_YF`). The two mechanisms are **separate material instances**: a single ``ASDPlasticMaterial3D`` object only has either the shear or the cap surface active, not both simultaneously; combining them (as PLAXIS does internally) requires using two separate materials (e.g. stacked in a ``Series3D`` wrapper or similar) — this is not something ``ASDPlasticMaterial3D`` does automatically.

The yield function is a hyperbolic stress-strain relation in terms of the deviatoric stress invariant :math:`q`, written as an implicit function of the plastic shear strain internal variable :math:`\varepsilon_q^{p\text{-shear}}`:

.. math::
   f = \dfrac{q}{E_i\left(1-q/q_a\right)} - \dfrac{q}{E_{ur}} - \varepsilon_q^{p\text{-shear}}

where :math:`q_f` is the Mohr-Coulomb deviatoric strength at the current minor principal (confining) stress :math:`\sigma_3`, :math:`q_a=q_f/R_f` is the hyperbola's asymptote, :math:`E_{50}` and :math:`E_{ur}` are the stress-dependent secant/unload-reload moduli (see :ref:`StiffSoil_EL`) and :math:`E_i = 2E_{50}/(2-R_f)` is the initial tangent modulus:

.. math::
   q_f = \left(c\cot\varphi + \sigma_3\right)\dfrac{2\sin\varphi}{1-\sin\varphi} \qquad q_a = q_f/R_f

Implementation notes: the plastic shear strain is capped at the value it would reach at :math:`q=q_f` so :math:`q` cannot exceed the Mohr-Coulomb strength regardless of further hardening; :math:`q` itself is capped (with a smooth linear extension) at :math:`0.99\,q_a` to avoid the hyperbola's singularity; and a Rankine-style tension cut-off (:math:`\sigma_3 > 0`, :math:`\sigma_1 > 0`) disables the shear surface in tension. The hardening function for :math:`\varepsilon_q^{p\text{-shear}}` is :math:`h=\sqrt{2/3}\,\lVert \mathrm{dev}(\vec{m})\rVert` (see :ref:`HardeningFunctions`). The yield function has zero size at the origin (:math:`f=0` for :math:`q=0` when :math:`\varepsilon_q^{p\text{-shear}}=0`), so **any** deviatoric loading starting from an unloaded state is immediately plastic; there is no finite initial elastic region in shear (consistent with how the Hardening-Soil model reproduces a smooth hyperbolic stress-strain curve from the first load increment).

.. admonition:: Internal variables defined

   .. csv-table::
      :header: "IV Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``EpsQpShear``, Scalar, :math:`\varepsilon_q^{p\text{-shear}}`, "Plastic deviatoric (shear) strain, paired with the ``StiffSoilShearHardening`` hardening function (see :ref:`HardeningFunctions`)."

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``MC_phi``, scalar, :math:`\varphi`, "Friction angle (degrees)."
      ``MC_c``, scalar, :math:`c`, "Cohesion (stress units)."
      ``MC_ds``, scalar, --, "Relative stress perturbation for the numerical stress-derivative of the yield function."
      ``SS_E50_ref``, scalar, :math:`E_{50}^{ref}`, "Secant stiffness at 50% of the deviatoric strength, at the reference pressure ``SS_pref``."
      ``SS_Eur_ref``, scalar, :math:`E_{ur}^{ref}`, "Unload/reload stiffness at the reference pressure ``SS_pref``."
      ``SS_Rf``, scalar, :math:`R_f`, "Failure ratio :math:`q_f/q_a` (typically 0.9)."
      ``SS_m``, scalar, :math:`m`, "Power exponent for the stress-dependent stiffness (shared with :ref:`StiffSoil_EL`)."
      ``SS_pref``, scalar, :math:`p_{ref}`, "Reference pressure at which ``SS_E50_ref``/``SS_Eur_ref`` are defined."

.. admonition:: Usage in ASDPlasticMaterial3D

   Must be paired with :ref:`StiffSoilShear_PF` and :ref:`StiffSoil_EL`, with the same internal variable (``EpsQpShear``) on both the yield function and the plastic flow direction. List all compiled combinations with:

   .. code-block:: tcl

       nDMaterial ASDPlasticMaterial3D 1 list StiffSoilShear_YF

   .. note::

      Only instantiation and a basic single-step run of this combination were verified for this documentation; no closed-form analytical check against the hyperbolic stress-strain response was performed.

.. _StiffSoilCap_YF:

StiffSoilCap_YF
""""""""""""""""

Defines the (volumetric) cap hardening mechanism of the Hardening-Soil model, the second of the two ``StiffSoil`` yield surfaces (see :ref:`StiffSoilShear_YF` for the shear surface and the note there about the two mechanisms being separate material instances). It is an elliptical cap in the :math:`p`-:math:`q` plane (compression-positive mean stress :math:`p` and deviatoric stress :math:`q=\sqrt{3J_2}`):

.. math::
   f_c = \left(\dfrac{q^\ast}{\alpha}\right)^2 + p^2 - p_c^2 \qquad
   q^\ast = \dfrac{q}{f(\theta)} \qquad
   f(\theta) = \dfrac{3-\sin\varphi}{2\left(\sqrt{3}\cos\theta - \sin\theta\sin\varphi\right)}

where :math:`\alpha` is the cap shape factor, :math:`p_c` is the cap pressure internal variable, and :math:`f(\theta)` reshapes the circular cap into a Mohr-Coulomb-compatible hexagon-like shape in the deviatoric plane as a function of the Lode angle :math:`\theta`. Flow on this surface is **associated** (the plastic potential equals :math:`f_c`, see :ref:`StiffSoilCap_PF`). The cap hardening law relates :math:`p_c` to the volumetric plastic strain (PLAXIS-style):

.. math::
   \varepsilon_v^{p\text{-cap}} = \dfrac{\beta}{1-m}\left(\dfrac{p_c}{p_{ref}}\right)^{1-m}

which, written as a hardening function :math:`h=dp_c/d\lambda`, only activates under compression (:math:`p_c` freezes, rather than decreasing, when the volumetric plastic flow direction indicates dilation/unloading) -- see :ref:`HardeningFunctions`. Two hardening-function variants are compiled: a nonlinear one following the law above (``CapPressure`` internal variable, hardening function ``StiffSoilCapHardening``) and a simplified linear one with constant modulus :math:`p_{ref}/\beta` (``CapPressureLinear`` internal variable, same type name ``CapPressure`` but hardening function ``StiffSoilCapLinearHardening``, so the two do **not** collapse into one when both the yield function and plastic flow direction use the same variant).

Like the shear surface, the cap has zero size at the origin when :math:`p_c` is initialized to zero (the default), so it yields immediately upon any compressive loading from an unloaded state; starting from a nonzero, pre-hardened :math:`p_c` instead gives a genuine elastic region below the cap.

.. admonition:: Internal variables defined

   .. csv-table::
      :header: "IV Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``CapPressure``, Scalar, :math:`p_c`, "Cap pressure, paired with either the ``StiffSoilCapHardening`` (nonlinear) or ``StiffSoilCapLinearHardening`` (linear) hardening function (see :ref:`HardeningFunctions`)."

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``MC_phi``, scalar, :math:`\varphi`, "Friction angle (degrees), used only through :math:`f(\theta)` above."
      ``MC_ds``, scalar, --, "Relative stress perturbation for the numerical stress-derivative of the yield function."
      ``SS_alpha``, scalar, :math:`\alpha`, "Cap shape factor."
      ``SS_pref``, scalar, :math:`p_{ref}`, "Reference pressure for the cap hardening law."
      ``SS_m``, scalar, :math:`m`, "Power exponent, shared with :ref:`StiffSoil_EL` and the cap hardening law."
      ``SS_beta``, scalar, :math:`\beta`, "Cap hardening (compressibility) parameter."

.. admonition:: Usage in ASDPlasticMaterial3D

   Must be paired with :ref:`StiffSoilCap_PF` and :ref:`StiffSoil_EL`, with the same internal variable (``CapPressure``, either hardening variant) on both the yield function and the plastic flow direction. List all compiled combinations with:

   .. code-block:: tcl

       nDMaterial ASDPlasticMaterial3D 1 list StiffSoilCap_YF

   .. note::

      Only instantiation and a basic single-step run of this combination were verified for this documentation; an attempt to analytically verify the elastic unload/reload stiffness against :ref:`StiffSoil_EL`'s :math:`E_{ur}` formula ran into convergence difficulties when driving the cap through a realistic loading/unloading history with this version of the solver, so no quantitative check is claimed here.


