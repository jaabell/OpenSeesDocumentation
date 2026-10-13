.. _ASDPlasticMaterial3D:

ASDPlasticMaterial3D
^^^^^^^^^^^^^^^^^^^^^^

| This command is used to construct an ``ASDPlasticMaterial3D`` material object. ``ASDPlasticMaterial3D`` implements a large family of constitutive models based on the classical theory of elastoplasticity using advanced template metaprogramming. Users build new constitutive models by selecting the yield function, plastic-flow direction, elasticity law, and hardening models for the internal variables from several possible options for each component. 

| This is the 3D-specific implementation that provides enhanced features compared to the base ``ASDPlasticMaterial`` class, including multiple integration methods, tangent operator options, and extensive response capabilities.

To create a new model, specify the Yield Function type (``$YieldFunctionType``), Plastic Flow type (``$PlasticFlowType``), and Elasticity type (``$ElasticityType``). All internal variables and model parameters are set to zero unless specified by the user, which might or not make sense depending on context, and this initialization is printed out to the screen. 

After setting the ``$YieldFunctionType``, ``$PlasticFlowType`` and ``$ElasticityType``, you can give initial values to internal variables within the ``Begin_Internal_Variables`` ... ``End_Internal_Variables`` block. Then, the ``Begin_Model_Parameters`` ... ``End_Model_Parameters`` block is used to provide model parameter values (these can be changed during the analysis with the ``setParameter`` command as expected). Finally, model integration options are set within the ``Begin_Integration_Options`` ... ``End_Integration_Options`` code block. Specification blocks can occur in any order or ommitted. 

The complete command looks as follows::

   nDMaterial ASDPlasticMaterial3D $tag 
      $YieldFunctionType 
      $PlasticFlowType $
      ElasticityType 
      $IV_TYPE 
      Begin_Internal_Variables 
         $InternalVariable1 $$double_value1 $$double_value2... $$double_valueN1  
         $InternalVariable2 $$double_value1 $$double_value2... $$double_valueN2 
         #... (depends on how many internal variables the particular selected model has) 
      End_Internal_Variables 
      Begin_Model_Parameters 
         $ModelParameters1 $$double_value1 
         $ModelParameters2 $$double_value2 
         #... (depends on how many model parameters the particular selected model has) 
      End_Model_Parameters 
      Begin_Integration_Options
         f_absolute_tol $double_value
         stress_absolute_tol $double_value
         n_max_iterations $int_value
         return_to_yield_surface (string) : Disabled | One_Step_Return | Iterative_Return
         integration_method (string) : Forward_Euler | Forward_Euler_Subincrement | Backward_Euler | Backward_Euler_LineSearch | Modified_Euler_Error_Control | Runge_Kutta_45_Error_Control | Runge_Kutta_45_Error_Control_old
         tangent_type (string) : Elastic | Numerical_Algorithmic_FirstOrder | Numerical_Algorithmic_SecondOrder | Continuum | Secant
         rk45_dT_min $double_value
         rk45_niter_max $int_value
      End_Integration_Options

Alternatively, list every ``$YieldFunctionType``/``$PlasticFlowType``/``$ElasticityType``/``$IV_TYPE`` combination that the factory was compiled with, optionally filtered by yield function name::

   nDMaterial ASDPlasticMaterial3D $tag list <$YieldFunctionType>


Explanation

.. csv-table:: 
   :header: "Argument", "Type", "Description"
   :widths: 10, 10, 40

   $tag, |integer|, "Unique tag identifying this material."
   $YieldFunctionType, |string|, "Mandatory. Yield function to be used -> :ref:`YieldFunctionType`"
   $PlasticFlowType, |string|, "Mandatory. Plastic flow direction to be used -> :ref:`PlasticFlowType`"
   $ElasticityType, |string|, "Mandatory. Elastic model to be used -> :ref:`ElasticityType`"
   $IV_TYPE, |string|, "Mandatory. Hardening model for internal variables. Admitted types depend on YF, PF, and EL chosen.  "
   Begin_Internal_Variables, |string|, "Optional. Marks the beginning of the code block to set the internal variables. If ommitted, all internal variables are initialized to zero. You can specify as many of the following variables as wanted. Ommitted variables are initialized to zero. Number and name of variables that can be set is model dependent (once YF, PF, and EL are specified)"
   $InternalVariable1, |list|, "Initial value of internal variable1. Dimension depends on internal variable type.  "
   $InternalVariable2, |list|, "Initial value of internal variable2.  "
   "--", "--", "... (input as many as model supports)"
   End_Internal_Variables, |string|, "Mandatory if block started. Marks the end of the code block to set the internal variables"
   Begin_Model_Parameters, |string|, "Optional. Marks the beginning of the code block to set the model parameters"
   $ModelParameters, |list|, "Values for parameters of the models to be used. This depends on the particular choices of ``$YieldFunctionType``, ``$PlasticFlowType``, ``$ElasticityType``, and ``$IV_type``. "
   "--", "--", "... (input as many as model supports)"
   End_Model_Parameters, |string|, "Mandatory if block started. Marks the beginning of the code block to set the model parameters"
   Begin_Integration_Options, |string|, "Optional. Marks the beginning of the code block to set the integration options. You can set any ammount "
   End_Integration_Options, |string|, "Mandatory if block started. Marks the beginning of the code block to set the model parameters"

|  The :ref:`YieldFunctionType`, :ref:`PlasticFlowType`, and :ref:`ElasticityType` have different variables and parameters to be set.

.. admonition:: Specification of internal variables (``$IV_TYPE``)

	All internal variables are specified in a single string with no spaces. Internal variables specifications are separated with a colon ``:``. After the name of the internal variable, the name of the hardening function must be provided in parenthesis. The specification string must end in a colon. The syntax is, thus:

	.. code-block::

		InternalVariable1(HardeningFunction1):InternalVariable2(HardeningFunction2):

	Internal variables are required for the yield function and plastic flow direction (see speficic components for details), and all internal variables must be provided with their hardening function otherwise instantiation fails.

	If the yield function and the plastic flow direction declare the exact same internal-variable/hardening-function combination (as, for example, ``HoekBrown_YF`` and ``HoekBrown_PF``, which both use a single unused ``BackStress`` placeholder), the two collapse into a single internal variable and the ``$IV_TYPE`` string only lists it once, e.g. ``BackStress(NullHardeningTensorFunction):`` (one entry, one trailing colon) rather than the same entry repeated twice.

.. admonition:: Note

    Any internal variable or parameter that is not specified is set to zero by default.

.. admonition:: Listing available combinations

   Since the valid ``$YieldFunctionType``/``$PlasticFlowType``/``$ElasticityType``/``$IV_TYPE`` combinations depend on how the material was compiled (see ``gen_ASD_material_definitions_CPP.py``), you can list them by passing ``list`` as the ``$YieldFunctionType`` argument, optionally followed by a yield function name to filter the (possibly very long) output::

      nDMaterial ASDPlasticMaterial3D $tag list <$YieldFunctionType>

   This prints every compiled ``YF``/``PF``/``EL``/``IV`` combination (or only those matching the given ``$YieldFunctionType`` if provided) to the console, without creating a material. Note that the factory generates the full cross-product of yield functions and plastic-flow directions for the "standard" models (e.g. you will also see entries pairing ``HoekBrown_YF`` with ``VonMises_PF``, which is not a physically meaningful combination), so check that both the ``YF`` *and* ``PF`` names in a listed entry are the ones you intend to use. The ``$IV_TYPE`` string printed for each entry must be copied exactly, including the trailing colon.

.. toctree::
   :caption: Arguments detailed description
   :maxdepth: 2

   ASDPlasticMaterial/YieldFunctions
   ASDPlasticMaterial/PlasticFlowType
   ASDPlasticMaterial/ElasticityType
   ASDPlasticMaterial/HardeningFunctions

.. _ASDPlasticMaterial3DTheory:
.. _ASDPlasticTheory:

ASDPlasticMaterial3D Theory
"""""""""""""""""""""""""""""

The theoretical foundation follows classical elastoplasticity theory (see :ref:`ASDPlasticTheory`). ``ASDPlasticMaterial3D`` provides additional implementation features:

* **Template Metaprogramming**: Uses C++ template metaprogramming for compile-time optimization
* **Multiple Integration Methods**: Offers several integration algorithms beyond the basic methods
* **Advanced Tangent Operators**: Provides different tangent computation strategies
* **Enhanced Response System**: Supports additional response queries and parameter updates

The material recieves the total (trial) strain :math:`\vec{\epsilon}^{\text{trial}}` from the finite element that contains it. From this, the trial strain increment is computed by subtracting the previously committed total strain:

.. math::
    \Delta \vec{\epsilon}^{\text{trial}} = \vec{\epsilon}^{\text{trial}} - \vec{\epsilon}^{\text{commit}}

The integration method selected determines how the stress increment is computed and how the plastic corrections are applied.

.. _`ASDPlasticMaterial3DIntegrationMethods`:

Advanced Integration Methods
""""""""""""""""""""""""""""""

``ASDPlasticMaterial3D`` supports multiple integration algorithms beyond the basic Forward Euler and Runge-Kutta methods:

.. csv-table:: 
   :header: "Integration Method", "Description"
   :widths: 30, 50

   ``Forward_Euler``, "Basic explicit forward Euler method with yield surface crossing detection"
   ``Forward_Euler_Subincrement``, "Forward Euler with automatic subincrementation for large strain increments"
   ``Backward_Euler``, "Implicit backward Euler method for better stability"
   ``Backward_Euler_LineSearch``, "Backward Euler with line search for enhanced convergence"
   ``Modified_Euler_Error_Control``, "Modified Euler method with adaptive error control"
   ``Runge_Kutta_45_Error_Control``, "4th/5th order Runge-Kutta with adaptive error control"
   ``Runge_Kutta_45_Error_Control_old``, "Older implementation of the RK45 error-controlled integrator, kept for backward compatibility"

.. admonition:: Integration Method Selection

   The integration method is selected in the ``Begin_Integration_Options`` block using the ``integration_method`` keyword. If not specified, **Backward_Euler** is used by default.

   .. note::

      Older versions (and older documentation) called this keyword ``method``. The parser only recognizes ``integration_method``; ``method`` is silently ignored and the default is used instead.


.. _`ASDPlasticMaterial3DTangentOperators`:

Tangent Operator Types
"""""""""""""""""""""""

``ASDPlasticMaterial3D`` provides several options for computing the consistent tangent operator:

.. csv-table:: 
   :header: "Tangent Operator", "Description"
   :widths: 30, 50

   ``Elastic``, "Returns the elastic tangent matrix (ignores plasticity)"
   ``Numerical_Algorithmic_FirstOrder``, "Computes algorithmic tangent using first-order finite differences"
   ``Numerical_Algorithmic_SecondOrder``, "Computes algorithmic tangent using second-order finite differences (more accurate but slower)"
   ``Continuum``, "Returns the continuum tangent operator"
   ``Secant``, "Returns the average of continuum and elastic tangents"

.. admonition:: Tangent Operator Selection

   The tangent operator type is selected in the ``Begin_Integration_Options`` block using the ``tangent_type`` keyword. If not specified, **Secant** is used by default, regardless of the chosen integration method.

   .. note::

      As with ``integration_method``/``method`` above, older versions called this keyword ``tangent``; only ``tangent_type`` is read.


.. _`ASDPlasticMaterial3DIntegrationOptions`:

Integration Options
"""""""""""""""""""

.. csv-table::
   :header: "Parameter", "Type", "Description"
   :widths: 10, 10, 40

   $f_absolute_tol, |float|, "Absolute tolerance on the yield function value used for yield-surface-crossing detection. Default: 1e-6."
   $stress_absolute_tol, |float|, "Absolute tolerance for the convergence of the (implicit) constitutive integration algorithm. Default: 1e-6."
   $n_max_iterations, |integer|, "Maximum number of iterations for constitutive integration. Default: 100."
   $return_to_yield_surface, |string|, "Whether/how to correct the stress back onto the yield surface after integration. One of ``Disabled``, ``One_Step_Return`` or ``Iterative_Return``. Any other value is treated as ``One_Step_Return``. Default: ``One_Step_Return``."
   $integration_method, |string|, "Constitutive integration method. See :ref:`ASDPlasticMaterial3DIntegrationMethods` for options. Default: ``Backward_Euler``."
   $tangent_type, |string|, "Tangent operator computation method. See :ref:`ASDPlasticMaterial3DTangentOperators` for options. Default: ``Secant``."
   $rk45_dT_min, |float|, "Minimum pseudo-time sub-increment allowed for the ``Runge_Kutta_45_Error_Control`` family of methods. Default: 1e-2."
   $rk45_niter_max, |integer|, "Maximum number of sub-increments allowed for the ``Runge_Kutta_45_Error_Control`` family of methods. Default: 110."

.. admonition:: Keyword names

   The keywords actually recognized inside ``Begin_Integration_Options`` ... ``End_Integration_Options`` are exactly as listed above (``f_absolute_tol``, ``stress_absolute_tol``, ``n_max_iterations``, ``return_to_yield_surface``, ``integration_method``, ``tangent_type``, ``rk45_dT_min``, ``rk45_niter_max``). Any other keyword is silently ignored. Older names such as ``f_relative_tol``/``stress_relative_tol``/``method``/``tangent_operator`` are **not** recognized by the parser.

The default integration method is **Backward_Euler** (an implicit scheme) with a **Secant** tangent operator; this was changed from the previous defaults of ``Runge_Kutta_45_Error_Control`` with an ``Elastic`` tangent. ``Runge_Kutta_45_Error_Control`` remains available and uses the classical RK45 ODE integration algorithm, employing a 4th-order prediction of the stress increment together with a 5th-order prediction to estimate the integration error. In this scheme the strain increment provided by the element to the Gauss point is sub-divided into sub-increments, a process which is automated such that the provided **$stress_absolute_tol** is met, subject to the ``rk45_dT_min``/``rk45_niter_max`` limits. This method is a robust standard method applicable across all possible combinations of components, although other approaches may be preferable for specific cases.

The different parameters are activated depending on the integration algorithm selected. The *Forward_Euler* family algorithms only use the **$return_to_yield_surface** parameter, while the error-controlled and backward-Euler families use the rest.

The **$f_absolute_tol** parameter comes into play when the yield surface is being crossed, that is, when the previous (committed) stress is within the yield surface and the elastic prediction of the stress increment brings the stress state beyond the yield surface. In that case, an elastic increment occurs until the yield surface is touched which requires iterations with the Brent root finding algorithm. This is used by all currently available integration methods.


.. _`ASDPlasticMaterial3DOtherFeatures`:

Other Features
""""""""""""""""""

.. admonition:: General parameters

    These parameters are defined for all models. 

    .. csv-table:: 
       :header: "Parameter", "Type", "Description"
       :widths: 10, 10, 40

       ``MassDensity``, scalar, Defines the material mass density :math:`\rho`.
       ``InitialP0``, scalar, "Stress value assigned to all three normal stress components (:math:`\sigma_{11}=\sigma_{22}=\sigma_{33}=p_0`, shear components zero) the first time the material receives a trial strain, as long as the stress has not already been set some other way (see ``stress_set_externally`` below). Since stresses use the tension-positive convention, use a *negative* value for a compressive confinement."

.. note::

   ``InitialP0`` is mainly intended to nudge the material away from the exactly-zero-stress state at the start of an analysis (all of the examples below use a tiny ``-1.0e-3``), which some yield surfaces are singular at. Using it to directly jump to a large confinement (instead of reaching that state through an actual loading history) was found, in testing for this documentation, to cause convergence difficulties for several yield-function/elasticity combinations; prefer applying a real initial loading stage if a specific non-trivial confinement is required.


.. admonition:: Enhanced Responses  (`setResponse` and `getResponse` behavior)

    * *Basic responses*. ``stresses`` for stress, ``strains`` for strains, and ``pstrains`` for plastic strains. 
    * *Enhanced stress measures*. ``eqpstrain`` for equivalent plastic strain, ``PStress`` for mean stress (:math:`p = (σ_{11}+σ_{22}+σ_{33})/3`), ``J2Stress`` for J2 invariant of stress.
    * *Enhanced strain measures*. ``VolStrain`` for volumetric strain (:math:`ε_v = ε_{11}+ε_{22}+ε_{33}`), ``J2Strain`` for J2 invariant of strain.
    * *Internal variables*. You can request any and all internal variables by their specific name as an output. 

.. admonition:: Advanced `setParameter` behavior

   * *State variable updates*. Can update ``stress``, ``strain``, ``plasticStrain`` and their ``trial...`` variants directly.
   * *Parameter updates*. Can update any model parameter by name using the generic parameter system.
   * *Special K0 operations*. ``K02D`` and ``K03D`` for setting K0 stress states in 2D/3D conditions.
   * *Stress increments*. ``trialStressIncrement`` adds the same value to the trial ``XX``, ``YY`` and ``ZZ`` normal stress components simultaneously; ``trialStressIncrementXX``/``YY``/``ZZ``/``XY``/``YZ``/``XZ`` add to one specific trial stress component. ``commitStressIncrementXX``/``YY``/``ZZ``/``XY``/``YZ``/``XZ`` do the same on the *committed* stress (there is no plain, all-components ``commitStressIncrement``, unlike the trial version).
   * *Effect on InitialP0*. Setting ``stress``, ``strain``, ``trialStrain``, ``trialStress``, or any of the ``trialStressIncrement...``/``commitStressIncrement...`` targets above marks the material as having its stress "set externally"; this disables the automatic ``InitialP0`` assignment on the first call to ``setTrialStrain`` (see the ``InitialP0`` note above) so that the externally imposed stress state is not silently overwritten.

.. admonition:: Internal Variable Management

   ``ASDPlasticMaterial3D`` provides methods to inspect and manage internal variables:
   
   * ``getInternalVariablesNames()`` - Returns list of internal variable names
   * ``getInternalVariableSizeByName(name)`` - Returns size of specified internal variable
   * ``getInternalVariableIndexByName(name)`` - Returns index of specified internal variable
   * ``setInternalVariableByName(name, size, values)`` - Sets internal variable values
   * ``getParameterNames()`` - Returns list of model parameter names
   * ``setParameterByName(name, value)`` - Sets model parameter value

Implementation details
""""""""""""""""""""""

``ASDPlasticMaterial3D`` is implemented using C++ template metaprogramming, with a header-only design and using the "eigen" C++ library for high-performance array operations. This design provides modularity and the ability to mix and match components to create new models, while also providing high-performance because runtime polymorphism is avoided. 

Key implementation features:
* **Template-based architecture**: Compile-time generation of optimized code for each material configuration
* **Eigen library**: High-performance linear algebra operations
* **Voigt notation**: Efficient tensor representation using 6-component vectors
* **Component modularity**: Easy extension with new yield functions, flow rules, elasticity models, and hardening functions


Example
"""""""

The following example defines an instance of ``ASDPlasticMaterial3D`` with a Drucker-Prager yield function, a (non-associated) Drucker-Prager plastic-flow direction, elastic-isotropic elasticity law and linear hardening for both internal variables, using advanced integration options. This exact command (material creation plus a one-element analysis) was run with the ``OpenSees`` binary and completes without error.

.. admonition:: TCL code

    .. code-block:: none

        nDMaterial ASDPlasticMaterial3D 1 \
            DruckerPrager_YF \
            DruckerPrager_PF \
            LinearIsotropic3D_EL \
            BackStress(TensorLinearHardeningFunction):DP_cohesion(ScalarLinearHardeningFunction): \
            Begin_Internal_Variables \
                DP_cohesion 1. \
                BackStress 0. 0. 0. 0. 0. 0. \
            End_Internal_Variables \
            Begin_Model_Parameters \
                YoungsModulus 1e8 \
                PoissonsRatio 0.3 \
                TensorLinearHardeningParameter 1e6 \
                ScalarLinearHardeningParameter 1e4 \
                DP_xi_c 1e4 \
                DP_eta 0.5 \
                DP_etabar 0.3 \
                MassDensity 2000. \
            End_Model_Parameters \
            Begin_Integration_Options \
                integration_method Runge_Kutta_45_Error_Control \
                tangent_type Continuum \
                f_absolute_tol 1e-8 \
                stress_absolute_tol 1e-6 \
                n_max_iterations 50 \
                return_to_yield_surface One_Step_Return \
            End_Integration_Options

.. admonition:: Python code

    .. code-block:: python

        ops.nDMaterial("ASDPlasticMaterial3D", 1,
        "DruckerPrager_YF",
        "DruckerPrager_PF",
        "LinearIsotropic3D_EL",
        "BackStress(TensorLinearHardeningFunction):DP_cohesion(ScalarLinearHardeningFunction):",
        "Begin_Internal_Variables",
            "DP_cohesion", 1.,
            "BackStress", 0., 0., 0., 0., 0., 0.,
        "End_Internal_Variables",
        "Begin_Model_Parameters",
            "YoungsModulus", 1e8,
            "PoissonsRatio", 0.3,
            "TensorLinearHardeningParameter", 1e6,
            "ScalarLinearHardeningParameter", 1e4,
            "DP_xi_c", 1e4,
            "DP_eta", 0.5,
            "DP_etabar", 0.3,
            "MassDensity", 2000.,
        "End_Model_Parameters",
        "Begin_Integration_Options",
            "integration_method", "Runge_Kutta_45_Error_Control",
            "tangent_type", "Continuum",
            "f_absolute_tol", 1e-8,
            "stress_absolute_tol", 1e-6,
            "n_max_iterations", 50,
            "return_to_yield_surface", "One_Step_Return",
        "End_Integration_Options",
        )

.. note::

   This page previously showed ``DruckerPrager_YF`` paired with ``ConstantDilatancy_PF`` and an internal variable named ``VonMisesRadius``. Neither exists: the scalar internal variable registered for ``DruckerPrager_YF``/``DruckerPrager_PF`` is named ``DP_cohesion`` (``YieldStress`` is the name used for :ref:`VonMises_YF`/:ref:`VonMises_PF` instead). ``ConstantDilatancy_PF`` is a von Mises-type flow rule (deviatoric direction from the ``BackStress``) and is compiled with :ref:`VonMises_YF`, :ref:`DruckerPrager_YF`, :ref:`MohrCoulomb_YF` and :ref:`HoekBrown_YF` (see :ref:`ConstantDilatancy_PF`). With ``DruckerPrager_PF``, its own ``DP_etabar`` parameter controls dilatancy.

Example: Using Enhanced Response Queries
""""""""""""""""""""""""""""""""""""""""

To access the enhanced response capabilities of ``ASDPlasticMaterial3D``, these are queried as **material** sub-responses of the element (not as node responses): ``recorder Element -ele $eleTag ... material $matNum $respName`` (here assuming the element has a single material, so ``$matNum`` is 1). This was verified with the ``DruckerPrager_YF``/``DruckerPrager_PF`` example above (material tag 1 on element 1):

.. admonition:: TCL Recorder Example

    .. code-block:: tcl

        # Basic responses
        recorder Element -ele 1 -file stress.out -time material 1 stress
        recorder Element -ele 1 -file strain.out -time material 1 strain

        # Enhanced stress measures
        recorder Element -ele 1 -file p_stress.out -time material 1 PStress
        recorder Element -ele 1 -file j2_stress.out -time material 1 J2Stress
        recorder Element -ele 1 -file eq_pstrain.out -time material 1 eqpstrain

        # Enhanced strain measures
        recorder Element -ele 1 -file vol_strain.out -time material 1 VolStrain
        recorder Element -ele 1 -file j2_strain.out -time material 1 J2Strain

        # Internal variable by name
        recorder Element -ele 1 -file backstress.out -time material 1 BackStress
        recorder Element -ele 1 -file cohesion.out -time material 1 DP_cohesion

Example: Parameter Updates During Analysis
"""""""""""""""""""""""""""""""""""""""""""""

``ASDPlasticMaterial3D`` supports parameter updates during analysis through the generic Tcl ``setParameter -value $value -ele $eleTag $paramName`` command, which forwards a single scalar value to the material's ``setParameter``/``updateParameter`` (element 1 below is assumed to use material tag 1):

.. admonition:: TCL Parameter Update

    .. code-block:: tcl

        # Update model parameters
        setParameter -value 2e8 -ele 1 YoungsModulus
        setParameter -value 0.25 -ele 1 PoissonsRatio
        setParameter -value 2e4 -ele 1 ScalarLinearHardeningParameter

        # Update internal variables
        setParameter -value 1.5 -ele 1 DP_cohesion

        # Set the (committed and trial) stress state one component at a time
        # (this also marks the material's stress as "set externally", see the
        # InitialP0 note above) -- here setting an isotropic 1 MPa stress state:
        setParameter -value 1e6 -ele 1 commitStressIncrementXX
        setParameter -value 1e6 -ele 1 commitStressIncrementYY
        setParameter -value 1e6 -ele 1 commitStressIncrementZZ

.. note::

   The plain Tcl ``setParameter`` command only carries a single scalar value (via ``-value``), so it cannot be used to set a full 6-component ``stress``/``strain``/``trialStress``/``trialStrain`` state in one call, even though those names are accepted by the material's own ``setParameter``/``updateParameter`` (which do accept a full ``Vector`` when driven directly, e.g. from Python through the lower-level parameter API). From Tcl, use the per-component ``trialStressIncrement{XX,YY,ZZ,XY,YZ,XZ}``/``commitStressIncrement{XX,YY,ZZ,XY,YZ,XZ}`` targets instead, one scalar ``setParameter`` call per component.

Example: Integration Method Selection
""""""""""""""""""""""""""""""""""""""""

Different integration methods for specific applications:

.. admonition:: Default / Robust Integration (Recommended for most cases)

    .. code-block:: tcl

        Begin_Integration_Options
            integration_method Backward_Euler
            tangent_type Secant
            f_absolute_tol 1e-6
            stress_absolute_tol 1e-6
            n_max_iterations 100
            return_to_yield_surface One_Step_Return
        End_Integration_Options

.. admonition:: Error-Controlled Integration (alternative, applicable across all component combinations)

    .. code-block:: tcl

        Begin_Integration_Options
            integration_method Runge_Kutta_45_Error_Control
            tangent_type Continuum
            f_absolute_tol 1e-8
            stress_absolute_tol 1e-6
            n_max_iterations 50
            return_to_yield_surface One_Step_Return
        End_Integration_Options

.. admonition:: Fast Integration (For large models)

    .. code-block:: tcl

        Begin_Integration_Options
            integration_method Forward_Euler_Subincrement
            tangent_type Elastic
            return_to_yield_surface One_Step_Return
        End_Integration_Options

.. admonition:: High Accuracy Integration (For research)

    .. code-block:: tcl

        Begin_Integration_Options
            integration_method Backward_Euler_LineSearch
            tangent_type Numerical_Algorithmic_SecondOrder
            f_absolute_tol 1e-12
            stress_absolute_tol 1e-10
            n_max_iterations 100
            return_to_yield_surface One_Step_Return
        End_Integration_Options


Verified Examples: HoekBrown_YF, MohrCoulomb_YF, DuncanChang_EL
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

The following scripts were run with the ``OpenSees`` binary against a hand (closed-form) solution, printing the computed ("got") value next to the expected one:

* :download:`ASDPlasticMaterial3D_HoekBrownExample.tcl` -- unconfined compression (:math:`\sigma_3=0`) of a single 8-node brick with :ref:`HoekBrown_YF`/:ref:`HoekBrown_PF`, :math:`GSI=50`, :math:`m_i=10`, :math:`D=0`, zero dilatancy (``HB_mb_psi 0``), using the default ``Backward_Euler``/``Secant`` integration options. Checked against the rock-mass unconfined compressive strength :math:`\sigma_{cm}=\sigma_{ci}\,s^a`: got :math:`3.0145\times10^6` Pa vs. expected :math:`3.0114\times10^6` Pa (0.10% relative error).
* :download:`ASDPlasticMaterial3D_MohrCoulombExample.tcl` -- the same unconfined-compression setup with ``MohrCoulomb_YF``/``MohrCoulomb_PF`` (:math:`\varphi=30^\circ`, :math:`c=10` kPa), checked against :math:`\sigma_{ucs}=2c\cos\varphi/(1-\sin\varphi)`: got :math:`3.4645\times10^4` Pa vs. expected :math:`3.4641\times10^4` Pa (0.01% relative error).
* :download:`ASDPlasticMaterial3D_DuncanChangExample.tcl` -- instantiates ``MohrCoulomb_YF``/``MohrCoulomb_PF``/:ref:`DuncanChang_EL` and lets the material's own ``Print()`` echo each of the four ``DuncanChang_EL`` parameters; running it confirms ``ReferenceYoungsModulus``, ``ReferencePressure``, ``DuncanChang_MaxSigma3`` and ``DuncanChang_n`` are each read back under their own distinct name, rather than colliding with ``YoungsModulus``.
* :download:`ASDPlasticMaterial3D_ConstantDilatancyExample.tcl` -- ``VonMises_YF``/:ref:`ConstantDilatancy_PF` in uniaxial compressive strain on one 8-node brick for ``Dilatancy`` :math:`D = 0.2, 0, -0.2`; the ratio of plastic volumetric strain to the norm of the deviatoric plastic strain comes out as exactly :math:`-D` (:math:`-0.2, 0, +0.2`).

Both compression examples use ``test NormDispIncr 1e-8 100`` with a 3D single-element model under roller/pin boundary conditions, incrementally loaded in displacement control until a stress peak is reached.

.. note::

   The ``StiffSoilShear_*``/``StiffSoilCap_*`` (Hardening-Soil) components (see :ref:`StiffSoilShear_YF`/:ref:`StiffSoilCap_YF`) were only checked for successful instantiation and a basic single-step run for this documentation; no analytical verification of their stiffness or hardening response is claimed. An attempt to verify the elastic unload/reload stiffness against :ref:`StiffSoil_EL`'s :math:`E_{ur}` formula directly ran into convergence difficulties with this version of the solver when imposing a realistic loading/unloading history or a large ``InitialP0`` confinement in a single step.


Code Developed by: **José A. Abell** (UANDES, Chile and ASDEA), **Guido Camata** and **Massimo Petracca**  (ASDEA Software, Italy).