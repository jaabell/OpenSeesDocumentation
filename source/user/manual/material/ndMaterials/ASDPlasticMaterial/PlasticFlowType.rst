.. _PlasticFlowType:

Plastic Flow Directions
^^^^^^^^^^^^^^^^^^^^^^^

Specifies the direction of plastic flow :math:`\mathbf{m}` used to define evolution of the plastic strain (see :ref:`ASDPlasticTheory`). The plastic flow direction determines how plastic strain components develop and influences both volumetric and deviatoric plastic deformation.

Plastic Flow Directions may define internal variables they need for their specification, as well as paramters. When specifying the ``ASDPlasticMaterial`` or ``ASDPlasticMaterial3D`` instance, one must provide internal variables mentioned below, together with their hardening function, when defining internal variables. 

.. note::
   :ref:`ASDPlasticMaterial3D` provides enhanced monitoring of plastic flow effects through specialized response queries like ``VolStrain`` and ``J2Strain`` to track volumetric and deviatoric plastic deformation separately.

Available functions:


.. _`VonMises_PF`:

VonMises_PF
"""""""""""
Defines a plastic flow direction derived from the `Von Mises Yield Criterion <https://en.wikipedia.org/wiki/Von_Mises_yield_criterion>`_. Its definition. It is the stress-derivative of the :ref:`VonMises_YF`.

.. math::
   \newcommand{\vec}[1]{\boldsymbol{#1}}
   \mathbf{m} = \dfrac{\partial f}{\partial \vec{\sigma}} = \dfrac{\vec{s} - \vec{\alpha} }{ \sqrt{ (\vec{s} - \vec{\alpha}) \cdot (\vec{s} - \vec{\alpha})}}

.. admonition:: Internal variables defined

   .. csv-table:: 
      :header: "IV Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``BackStress``, Rank-6 Tensor , :math:`\vec{\alpha}`,  "Backstress, definining location in stress space for axis of Von-Mises cylinder. "

.. admonition:: Parameters required

   None required for VonMises plastic flow. Parameters are inherited from associated yield function and hardening functions.

.. admonition:: Usage in ASDPlasticMaterial3D

   When using VonMises_PF with :ref:`ASDPlasticMaterial3D`, the plastic flow direction is automatically computed as the stress derivative of the Von Mises yield function. This provides:
   
   * Associated plastic flow (flow rule equals yield function gradient)
   * No volumetric plastic strain (isochoric plastic deformation)
   * Purely deviatoric plastic response
   
   You can monitor plastic strain components (assuming material tag 1 is attached to element 1):

   .. code-block:: tcl

       recorder Element -ele 1 -file plastic_strain.out -time material 1 pstrain


.. _`DruckerPrager_PF`:

DruckerPrager_PF
""""""""""""""""
Defines a plastic flow direction for use with :ref:`DruckerPrager_YF` (or other yield functions): the gradient of the Drucker-Prager potential :math:`g = \sqrt{J_2} + \bar\eta\, p`, with the dilation parameter ``DP_etabar`` in place of the friction slope. It is associated with :ref:`DruckerPrager_YF` when ``DP_etabar`` equals ``DP_eta``, and non-associated otherwise:

.. math::

        \mathbf{m} = \dfrac{\vec{s} - \vec{\alpha} }{ 2\sqrt{ \dfrac{1}{2}(\vec{s} - \vec{\alpha}) : (\vec{s} - \vec{\alpha})}} + \dfrac{\bar\eta}{3} \vec{I}

.. note::

   Before 2026-11 the deviatoric part lacked the factor 2 in the denominator (twice the gradient), so ``DP_etabar = DP_eta`` was not associated, and for a given ``DP_etabar`` the dilatancy was half of what it is now.

.. admonition:: Internal variables defined

   It needs the same two internal variables as :ref:`DruckerPrager_YF` (and they must be identical on both components): the ``BackStress`` tensor and a scalar, here registered under the name ``DP_cohesion`` (not actually referenced by this component's own flow-direction formula; it is only required so the internal-variable storage matches the paired yield function).

   .. csv-table::
      :header: "IV Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``BackStress``, Rank-6 Tensor , :math:`\vec{\alpha}`,  "Backstress, definining the location in stress space for the axis of the Drucker-Prager cone. "
      ``DP_cohesion``, Scalar , :math:`\kappa`,  "Not used by the flow direction; the hardening cohesion of :ref:`DruckerPrager_YF`."

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``DP_etabar``, Scalar, :math:`\bar\eta`, "Dilation parameter controlling the volumetric part of the plastic flow. Set equal to the yield function's ``DP_eta`` for associated flow, or smaller (even 0) for non-associated flow with reduced/zero dilatancy."

.. admonition:: Usage in ASDPlasticMaterial3D

   DruckerPrager_PF provides non-associated flow when used with pressure-sensitive yield functions. Key characteristics:

   * Pressure-dependent plastic flow (includes volumetric component)
   * Independently adjustable dilation via ``DP_etabar``
   * Suitable for geomaterials exhibiting dilatancy or contractancy

   Monitor volumetric plastic strain (assuming material tag 1 is attached to element 1):

   .. code-block:: tcl

       recorder Element -ele 1 -file vol_strain.out -time material 1 VolStrain


.. _`ConstantDilatancy_PF`:

ConstantDilatancy_PF
""""""""""""""""""""

Von-Mises PF provides no volumetric change (dilatancy) during plasticity. On the other hand Drucker-Prager PF provides a constant negative volumetric change which is proportional to the current value of the :math:`k` parameter. This PF defines a controllable dilatancy during plasticity by specifying a constant dilatancy coeficient :math:`D`.


.. math::

        \mathbf{m} = \dfrac{\partial f}{\partial \vec{\sigma}} = \dfrac{\vec{s} - \vec{\alpha} }{ \sqrt{ (\vec{s} - \vec{\alpha}) \cdot (\vec{s} - \vec{\alpha})}} - \dfrac{D}{3} \vec{I} ;

.. admonition:: Internal variables defined


   .. csv-table:: 
      :header: "IV Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``BackStress``, Rank-6 Tensor , :math:`\vec{\alpha}`,  "Backstress, definining the location in stress space for the axis of the Drucker-Prager cone. "

.. admonition:: Parameters required

   .. csv-table:: 
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``Dilatancy``, Scalar, :math:`D`, "Defines the rate of dilatancy with plastic flow. Positive values specify negative plastic volumetric change."

.. admonition:: Usage in ASDPlasticMaterial3D

   ConstantDilatancy_PF provides non-associated flow with controllable dilatancy. This is particularly useful for:
   
   * Concrete and rock materials (positive dilatancy)
   * Dense sands (positive dilatancy initially, then contractancy)
   * Loose sands (continuous contractancy)
   
   The ratio of plastic volumetric strain to the norm of the deviatoric plastic strain is :math:`-D`. It can be
   checked from the material's ``pstrain`` response (6 components; the first three are the normal components):

   .. code-block:: tcl

       recorder Element -ele 1 -file pstrain.out -time material 1 pstrain

   :download:`../ASDPlasticMaterial3D_ConstantDilatancyExample.tcl` pairs it with :ref:`VonMises_YF`
   (internal variables ``BackStress(TensorLinearHardeningFunction):YieldStress(ScalarLinearHardeningFunction):``) in
   uniaxial compressive strain and prints this ratio for :math:`D = 0.2, 0, -0.2`. It gives exactly
   :math:`-0.2, 0, +0.2`.


.. _`MohrCoulomb_PF`:

MohrCoulomb_PF
"""""""""""""""

Plastic flow direction paired with :ref:`MohrCoulomb_YF`: the gradient of the Mohr-Coulomb potential, which is the yield function with the dilatancy angle :math:`\psi` in place of the friction angle, corners rounded the same way (parameter ``MC_theta_T``, see :ref:`MohrCoulomb_YF`):

.. math::
   g(\vec{\sigma}) = \left(\cos\theta - \dfrac{\sin\theta\sin\psi}{\sqrt{3}}\right)\sqrt{J_2} + \dfrac{I_1 \sin\psi}{3} - c\cos\psi \qquad
   \mathbf{m} = \dfrac{\partial g}{\partial \vec{\sigma}}

The gradient is computed by central differences (relative perturbation ``MC_ds``).

.. note::

   Before 2026-11 the deviatoric part of :math:`\mathbf{m}` was taken from the potential with :math:`\varphi` and only its volumetric part was set to :math:`\sin\psi/3`; for :math:`\psi \neq \varphi` the Lode-angle dependence of the flow now follows :math:`\psi`.

Setting ``MC_psi`` to 0 gives zero dilatancy (deviatoric-only, isochoric plastic flow); setting it equal to ``MC_phi`` gives associated flow.

.. admonition:: Internal variables defined

   Same unused ``BackStress(NullHardeningTensorFunction)`` placeholder as :ref:`MohrCoulomb_YF`.

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``MC_phi``, Scalar, :math:`\varphi`, "Friction angle (degrees)."
      ``MC_c``, Scalar, :math:`c`, "Cohesion."
      ``MC_ds``, Scalar, --, "Relative stress perturbation for the numerical flow-direction derivative."
      ``MC_psi``, Scalar, :math:`\psi`, "Dilatancy angle (degrees); 0 for zero dilatancy."
      ``MC_theta_T``, Scalar, :math:`\theta_T`, "Lode angle (degrees) above which the corners are rounded, shared with :ref:`MohrCoulomb_YF`. 0 or not given: 29.9."

.. admonition:: Usage in ASDPlasticMaterial3D

   Always pair with :ref:`MohrCoulomb_YF`. Verified together with the yield function in :download:`../ASDPlasticMaterial3D_MohrCoulombExample.tcl` (``MC_psi 0.0``, zero dilatancy) -- see :ref:`ASDPlasticMaterial3D`.

   .. code-block:: tcl

       recorder Element -ele 1 -file vol_strain.out -time material 1 VolStrain


.. _`HoekBrown_PF`:

HoekBrown_PF
""""""""""""

Non-associated plastic flow direction for :ref:`HoekBrown_YF`. The plastic potential has the same generalized Hoek-Brown form as the yield function, but uses a separate (typically lower) dilation parameter ``HB_mb_psi`` in place of :math:`m_b`, while reusing the same :math:`s` and :math:`a`:

.. math::
   g = \sigma_1 - \sigma_3 - \sigma_{ci}\left(\max(m_{b,\psi}\,\sigma_3/\sigma_{ci} + s,\, 0)\right)^a

with :math:`\sigma_1 \geq \sigma_3` compression positive, as in the yield function, and the same edge rounding (parameter ``HB_theta_T``, see :ref:`HoekBrown_YF`). :math:`\mathbf{m} = \partial g/\partial \vec{\sigma}` is evaluated by central differences (perturbation ``HB_ds``, scaled by the stress norm).

.. note::

   Before 2026-11 the potential took the principal stresses of the tension-positive stress, so its :math:`\sigma_3` was the most compressive one: under compression the argument of the power was negative and the flow reduced to that of :math:`\sigma_1 - \sigma_3` (no dilatancy, whatever ``HB_mb_psi``). Setting ``HB_mb_psi`` to 0 gives zero dilatancy; non-associated flow (:math:`m_{b,\psi} < m_b`) is essential here because an associated flow rule (:math:`m_{b,\psi}=m_b`) would predict unrealistically large dilation for a rock mass.

.. admonition:: Internal variables defined

   Like :ref:`HoekBrown_YF`, requires the same unused ``BackStress(NullHardeningTensorFunction)`` placeholder (and, since both declare the identical type, the two collapse into a single internal variable for the combined material).

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``HB_sigci``, scalar, :math:`\sigma_{ci}`, "Unconfined compressive strength of the intact rock."
      ``HB_mb_psi``, scalar, ":math:`m_{b,\psi}`", "Dilation parameter, analogous to :math:`m_b` but controlling volumetric plastic strain. Use 0 for zero dilatancy."
      ``HB_GSI``, scalar, :math:`GSI`, "Geological Strength Index, 0-100 (used to derive :math:`s` and :math:`a`, and :math:`m_b` if ``HB_mb_psi`` overrides are not involved)."
      ``HB_mi``, scalar, :math:`m_i`, "Intact-rock material constant."
      ``HB_D``, scalar, :math:`D`, "Disturbance factor, 0-1."
      ``HB_s``, scalar, :math:`s`, "Optional direct override for the derived :math:`s`; only used if :math:`> 0`."
      ``HB_a``, scalar, :math:`a`, "Optional direct override for the derived :math:`a`; only used if :math:`> 0`."
      ``HB_ds``, scalar, --, "Relative stress perturbation used for the numerical flow-direction derivative."
      ``HB_theta_T``, scalar, :math:`\theta_T`, "Lode angle (degrees) above which the edges are rounded, shared with :ref:`HoekBrown_YF`. 0 or not given: 29.9."

.. admonition:: Usage in ASDPlasticMaterial3D

   Always pair with :ref:`HoekBrown_YF`. See the worked unconfined-compression example on the :ref:`ASDPlasticMaterial3D` page, which uses ``HB_mb_psi 0.0`` (zero dilatancy).


.. _`StiffSoilShear_PF`:

StiffSoilShear_PF
""""""""""""""""""

Non-associated plastic flow direction for the deviatoric (shear) mechanism of the Hardening-Soil model, paired with :ref:`StiffSoilShear_YF`. The plastic potential is a Mohr-Coulomb-type surface using the dilatancy angle :math:`\psi` in place of the friction angle :math:`\varphi`:

.. math::
   G = \left(\cos\theta - \dfrac{\sin\theta\sin\psi}{\sqrt{3}}\right)\sqrt{J_2} + \dfrac{I_1 \sin\psi}{3} - c\cos\psi

The dilatancy angle used is not the raw input ``MC_psi`` but a *mobilized* dilatancy angle :math:`\psi_m`, computed from Rowe's stress-dilatancy theory as a function of the current mobilized friction angle (PLAXIS Eqs. 15.6-15.8):

.. math::
   \sin\varphi_{cv} = \dfrac{\sin\varphi - \sin\psi}{1-\sin\varphi\sin\psi} \qquad
   \sin\varphi_m = \dfrac{\sigma_1-\sigma_3}{\sigma_1+\sigma_3-2c\cot\varphi} \qquad
   \sin\psi_m = \dfrac{\sin\varphi_m - \sin\varphi_{cv}}{1-\sin\varphi_m\sin\varphi_{cv}}

with :math:`\psi_m` clamped to be non-negative. :math:`\mathbf{m}=\partial G/\partial\vec{\sigma}` is then evaluated numerically (perturbation ``MC_ds``) and normalized to unit norm.

.. admonition:: Internal variables defined

   Same ``EpsQpShear`` internal variable as :ref:`StiffSoilShear_YF` (required to be identical on both components).

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``MC_phi``, scalar, :math:`\varphi`, "Friction angle (degrees)."
      ``MC_psi``, scalar, :math:`\psi`, "Ultimate dilatancy angle (degrees); set to 0 for zero dilatancy."
      ``MC_c``, scalar, :math:`c`, "Cohesion."
      ``MC_ds``, scalar, --, "Relative stress perturbation for the numerical flow-direction derivative."

.. admonition:: Usage in ASDPlasticMaterial3D

   Always pair with :ref:`StiffSoilShear_YF` and :ref:`StiffSoil_EL`.

   .. note::

      Only instantiation and a basic single-step run were verified for this documentation.


.. _`StiffSoilCap_PF`:

StiffSoilCap_PF
""""""""""""""""

**Associated** plastic flow direction for the cap (volumetric) mechanism of the Hardening-Soil model, paired with :ref:`StiffSoilCap_YF`: the plastic potential is identical to the cap yield function,

.. math::
   G_c = \left(\dfrac{q^\ast}{\alpha}\right)^2 + p^2 - p_c^2

and :math:`\mathbf{m}=\partial G_c/\partial\vec{\sigma}` is evaluated by numerical differentiation (perturbation ``MC_ds``, scaled by the stress norm), without normalization.

.. admonition:: Internal variables defined

   Same ``CapPressure`` internal variable (either hardening variant) as :ref:`StiffSoilCap_YF` (required to be identical on both components).

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter Name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

      ``MC_phi``, scalar, :math:`\varphi`, "Friction angle (degrees), used only through the deviatoric-plane shape function :math:`f(\theta)`."
      ``MC_ds``, scalar, --, "Relative stress perturbation for the numerical flow-direction derivative."
      ``SS_alpha``, scalar, :math:`\alpha`, "Cap shape factor."

.. admonition:: Usage in ASDPlasticMaterial3D

   Always pair with :ref:`StiffSoilCap_YF` and :ref:`StiffSoil_EL`.

   .. note::

      Only instantiation and a basic single-step run were verified for this documentation.

