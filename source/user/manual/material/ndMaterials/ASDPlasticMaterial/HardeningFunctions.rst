.. _`HardeningFunctions`:

Hardening Functions
^^^^^^^^^^^^^^^^^^^

Internal variables evolve accoding with their own laws to provide plastic hardening to the constitutive model. These laws are specified as hardening functions that specify an ODE for the evolution of the internal variable. Two types of internal variable are considered: scalar-valued and tensor-valued internal variables. These evolve in the following manner:

.. math::
   \newcommand{\vec}[1]{\boldsymbol{#1}}
   \newcommand{\state}{\sigma, \left\lbrace iv \right\rbrace, \left\lbrace param \right\rbrace }

   s^{\text{trial}} = s^{\text{commit}} + \Delta \lambda  h_s(\state)

   \vec{T}^{\text{trial}} = \vec{T}^{\text{commit}} + \Delta \lambda  \vec{h}_T(\state)

Where :math:`s` is a scalar-valued internal variable and :math:`\vec{T}` is a tensor-valued. These functions are used to define the hardening term in the plastic multiplier (see :ref:`ASDPlasticTheory`). 

.. note::
   When using :ref:`ASDPlasticMaterial3D`, hardening function parameters can be updated during analysis using ``setParameter``. Internal variables can be accessed by name for monitoring and recording. This enables real-time tracking of hardening evolution and allows for modeling of complex material behavior including state-dependent hardening, temperature effects, or damage-coupled hardening laws.

Available functions:


.. _ScalarValuedHF:

Hardening Functions for Scalar-Valued Internal Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""

**ScalarLinearHardeningFunction**

Provides linear hardening for the scalar variable, as a function of the plastic flow direction :

.. math::
   h_s(\state) = H \cdot \sqrt{  (2/3) \vec{m} \cdot \vec{m} } 


Where :math:`\vec{m}` is the plastic flow direction computed at the current state. 

.. admonition:: Parameters required

   .. csv-table:: 
      :header: "Parameter name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``ScalarLinearHardeningParameter``, scalar, :math:`H`, Linear hardening constant (Pa per unit plastic strain)

.. admonition:: Usage in ASDPlasticMaterial3D

   When used with :ref:`ASDPlasticMaterial3D`, ScalarLinearHardeningFunction provides:
   
   * Linear increase/decrease of scalar variable with plastic deformation
   * Isotropic hardening/softening behavior
   * Simple calibration with single parameter
   
   Monitor scalar internal variable evolution (e.g. the ``YieldStress`` internal variable of :ref:`VonMises_YF`, assuming material tag 1 is attached to element 1):

   .. code-block:: tcl

       recorder Element -ele 1 -file yieldstress.out -time material 1 YieldStress
       # Update hardening parameter during analysis
       setParameter -value 5e6 -ele 1 ScalarLinearHardeningParameter


.. _TensorValuedHF:

Hardening Functions for Tensor-Valued Internal Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""

**TensorLinearHardeningFunction**

Provides linear hardening for the tensor variable, as a function of the deviatoric plastic flow direction :

.. math::

   h_T(\state) = H \vec{m}_{dev}


Where :math:`\vec{m}_{dev}` is the deviatoric part of the plastic flow direction computed at the current state. 

.. admonition:: Parameters required

   .. csv-table:: 
      :header: "Parameter name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``TensorLinearHardeningParameter``, scalar, :math:`H`, Linear hardening constant (dimensionless)

.. admonition:: Usage in ASDPlasticMaterial3D

   When used with :ref:`ASDPlasticMaterial3D`, TensorLinearHardeningFunction provides:
   
   * Linear evolution of backstress tensor
   * Kinematic hardening behavior
   * Translation of yield surface in stress space
   
   The backstress evolves in the direction of deviatoric plastic flow, providing Bauschinger effect modeling.
   
   Monitor tensor internal variable evolution (assuming material tag 1 is attached to element 1):

   .. code-block:: tcl

       recorder Element -ele 1 -file backstress.out -time material 1 BackStress
       # Update hardening parameter during analysis
       setParameter -value 0.01 -ele 1 TensorLinearHardeningParameter

**ArmstrongFrederickHardeningFunction**

A type of hardening with saturation.

.. math::
   h_T(\state) = (2 / 3) h_a \vec{m}_{dev} - c_r \sqrt{  (2/3) \vec{m}_{dev} \cdot \vec{m}_{dev} } \cdot  \vec{T}


Where :math:`\vec{m}_{dev}` is the deviatoric part of the plastic flow direction computed at the current state. Model paramters :math:`h_a` and :math:`c_r`  specify the maximum (saturation) value and the saturation rate. The saturation value for the internal variable will be such that:

.. math::
   \Vert \vec{T} \Vert = \sqrt{\dfrac{2}{3}} \dfrac{h_a}{c_r}

Setting :math:`c_r = 0` results in linear hardening. 

.. admonition:: Parameters required

   .. csv-table:: 
      :header: "Parameter name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``AF_ha``, scalar, :math:`h_a`, Model constant for the linear part of the hardening model. Controls the rate of saturation (Pa).
       ``AF_cr``, scalar, :math:`c_r`, Model constant for saturation part of the hardening model. Controls saturation value (dimensionless).

.. admonition:: Usage in ASDPlasticMaterial3D

   When used with :ref:`ASDPlasticMaterial3D`, ArmstrongFrederickHardeningFunction provides:
   
   * Non-linear kinematic hardening with saturation
   * Dynamic recovery term for realistic cyclic response
   * Bauschinger effect modeling with memory
   
   The hardening combines:
   
   * **Linear term**: (2/3) :math:`h_a \vec{m}_{dev}` - drives hardening
   * **Recovery term**: :math:`-c_r \sqrt{(2/3) \vec{m}_{dev} \cdot \vec{m}_{dev}} \cdot \vec{T}` - provides saturation
   
   Setting :math:`c_r = 0` reduces to linear kinematic hardening.
   
   The saturation value for the internal variable will be:
   
   .. math::
      \Vert \vec{T} \Vert = \sqrt{\dfrac{2}{3}} \dfrac{h_a}{c_r}
   
   Monitor non-linear hardening (assuming material tag 1 is attached to element 1):

   .. code-block:: tcl

       recorder Element -ele 1 -file backstress.out -time material 1 BackStress
       recorder Element -ele 1 -file eqpstrain.out -time material 1 eqpstrain
       # Update hardening parameters during analysis
       setParameter -value 1e8 -ele 1 AF_ha
       setParameter -value 100 -ele 1 AF_cr

**NullHardeningScalarFunction** / **NullHardeningTensorFunction**

Trivial hardening functions that always return zero (:math:`h_s=0` / :math:`\vec{h}_T=\vec{0}`), i.e. the paired internal variable never evolves. These are used whenever an internal variable is required by the type system but is not actually meant to harden, e.g. the unused ``BackStress`` placeholder required by ``MohrCoulomb_YF``/``MohrCoulomb_PF`` and by :ref:`HoekBrown_YF`/:ref:`HoekBrown_PF` (both of which are perfectly-plastic criteria with no internal hardening state).

.. admonition:: Parameters required

   None.


.. _StiffSoilHF:

Hardening Functions for the Hardening-Soil (StiffSoil) Model
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

These hardening functions are specific to the ``StiffSoilShear_*``/``StiffSoilCap_*`` components (see :ref:`YieldFunctionType`/:ref:`PlasticFlowType`).

**StiffSoilShearHardening**

Hardening function for the ``EpsQpShear`` (plastic deviatoric strain) internal variable used by :ref:`StiffSoilShear_YF`. It accumulates the equivalent deviatoric part of the plastic flow direction:

.. math::
   h = \sqrt{\dfrac{2}{3}} \left\lVert \mathrm{dev}(\vec{m}) \right\rVert

.. admonition:: Parameters required

   None.

**StiffSoilCapHardening**

Nonlinear hardening function for the ``CapPressure`` internal variable used by :ref:`StiffSoilCap_YF`, following the PLAXIS cap hardening law :math:`\varepsilon_v^{p\text{-cap}} = (\beta/(1-m))(p_c/p_{ref})^{1-m}` differentiated to give:

.. math::
   h = \dfrac{p_{ref}}{\beta}\left(\dfrac{p_c}{p_{ref}}\right)^m \left\lvert \mathrm{tr}(\vec{m}) \right\rvert

:math:`p_c` is floored at :math:`0.1\,p_{ref}`, and :math:`h` is forced to zero whenever the plastic flow direction indicates dilation/unloading rather than compaction, so the cap can only expand, never shrink.

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``SS_pref``, scalar, :math:`p_{ref}`, Reference pressure.
       ``SS_beta``, scalar, :math:`\beta`, Cap hardening (compressibility) parameter.
       ``SS_m``, scalar, :math:`m`, Power exponent (shared with :ref:`StiffSoil_EL`).

**StiffSoilCapLinearHardening**

Simplified, linear alternative to ``StiffSoilCapHardening`` for the same ``CapPressure`` internal variable (used by the ``CapPressureLinear`` combination of :ref:`StiffSoilCap_YF`/:ref:`StiffSoilCap_PF`), with a constant hardening modulus :math:`p_{ref}/\beta` and the same one-way (compaction-only) behavior:

.. math::
   h = \begin{cases} \dfrac{p_{ref}}{\beta}\left\lvert \mathrm{tr}(\vec{m}) \right\rvert & \mathrm{tr}(\vec{m}) < 0 \\ 0 & \text{otherwise} \end{cases}

.. admonition:: Parameters required

   .. csv-table::
      :header: "Parameter name", "Type", "Symbol", "Description"
      :widths: 10, 10, 10, 70

       ``SS_pref``, scalar, :math:`p_{ref}`, Reference pressure.
       ``SS_beta``, scalar, :math:`\beta`, Cap hardening (compressibility) parameter.

