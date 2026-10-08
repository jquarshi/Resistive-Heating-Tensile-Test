# ==============================================================================
# 2D Coupled Thermo-Mechanical Joule Heating + Tensile Necking Simulation
#
# Geometry & Loading:
#   - Wire Length (L0): 0.1 m (10 cm)
#   - Strain Rate: 5e-3 s^-1
#   - Pull Velocity v = 5e-4 m/s (applied at y = 0.1 m)
#   - Target Engineering Strain: 15% (Delta L = 15 mm)
#   - Total Simulation Time: t_end = 30.0 s
# ==============================================================================

[Mesh]
  [gmg]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 10
    ny = 50
    xmin = 0.0
    xmax = 0.005 # 5 mm wire thickness
    ymin = 0.0
    ymax = 0.1   # 10 cm wire length (L0)
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Variables]
  # Temperature variable
  [T]
    initial_condition = 293.15 # Room temperature (K)
  [../]

  # Mechanical displacement variables
  [disp_x]
  [../]
  [disp_y]
  [../]
[]

# Automatically creates Kernels for 2D Solid Mechanics (Stress Equilibrium)
[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = FINITE # Finite strain formulation to capture large geometric necking
    add_variables = false
    generate_output = 'stress_yy strain_yy plastic_strain_yy'
  [../]
[]

[Kernels]
  # Transient heat storage: rho * Cp * (dT/dt)
  [heat_time_derivative]
    type = ADHeatConductionTimeDerivative
    variable = T
    specific_heat = specific_heat_copper
    density_name = density_copper
  [../]

  # Thermal conduction: -div(k * grad(T))
  [heat_conduction]
    type = ADHeatConduction
    variable = T
    thermal_conductivity = thermal_conductivity_copper
  [../]

  # Reads material property 'joule_source_property' into heat PDE
  [joule_heating]
    type = ADMatHeatSource
    variable = T
    material_property = 'joule_source_property'
  [../]
[]

[Functions]
  # Displacement pull function enforcing strain rate dot_eps = 5e-3 s^-1
  # v = dot_eps * L0 = 5e-3 * 0.1 = 5e-4 m/s
  [pull_func]
    type = ParsedFunction
    expression = '0.0005 * t'
  [../]

  # Temperature-Dependent Yield Stress Table (Thermal Softening)
  [yield_stress_func]
    type = PiecewiseLinear
    x = '293.15 400.0  600.0  800.0  1000.0' # Temp (K)
    y = '70.0e6 61.0e6 44.2e6 27.4e6 10.0e6' # Yield Stress (Pa)
  [../]
[]

[BCs]
  # --- Thermal Boundary Conditions ---
  # Clamped electrical contacts act as isothermal heat sinks at 293.15 K
  [clamped_bottom_thermal]
    type = ADDirichletBC
    variable = T
    boundary = 'bottom'
    value = 293.15
  [../]

  [clamped_top_thermal]
    type = ADDirichletBC
    variable = T
    boundary = 'top'
    value = 293.15
  [../]

  # --- Mechanical Boundary Conditions ---
  # Fix bottom boundary vertically
  [fix_y_bottom]
    type = DirichletBC
    variable = disp_y
    boundary = 'bottom'
    value = 0.0
  [../]

  # Pin bottom-left corner to prevent rigid horizontal sliding
  [fix_x_bottom]
    type = DirichletBC
    variable = disp_x
    boundary = 'bottom'
    value = 0.0
  [../]

  # Apply upward displacement to pull wire in tension at 5e-4 m/s
  [pull_top]
    type = FunctionDirichletBC
    variable = disp_y
    boundary = 'top'
    function = 'pull_func'
  [../]
[]

[Materials]
  # --- Thermal Material Properties ---
  [k]
    type = ADGenericConstantMaterial
    prop_names = 'thermal_conductivity_copper'
    prop_values = '397.48'
  [../]

  [cp]
    type = ADGenericConstantMaterial
    prop_names = 'specific_heat_copper'
    prop_values = '385.0'
  [../]

  [rho]
    type = ADGenericConstantMaterial
    prop_names = 'density_copper'
    prop_values = '8920.0'
  [../]

  # Joule Heating Source Property Q(T)
  [joule_mat]
    type = ADParsedMaterial
    property_name = 'joule_source_property'
    coupled_variables = 'T'
    constant_names = 'J_val sigma_0 alpha T_ref'
    constant_expressions = '60e6 5.96e7 0.00393 293.15'
    expression = '(J_val^2) / (sigma_0 / (1 + alpha * (T - T_ref)))'
  [../]

  # --- Mechanical Material Properties ---
  # Elasticity parameters for Copper
  [elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 110e9 # 110 GPa
    poissons_ratio = 0.34
  [../]

  # Thermal Expansion Tensor
  [thermal_expansion]
    type = ComputeThermalExpansionEigenstrain
    temperature = T
    stress_free_temperature = 293.15
    thermal_expansion_coeff = 16.5e-6 # 16.5 um/m-K
    eigenstrain_name = thermal_eigenstrain
  [../]

  # Plasticity Model using function-based yield stress
  [plasticity]
    type = IsotropicPlasticityStressUpdate
    yield_stress_function = yield_stress_func
    hardening_constant = 500e6 # 500 MPa Isotropic Hardening Modulus
  [../]

  # Total Stress Calculation
  [stress]
    type = ComputeMultipleInelasticStress
    inelastic_models = 'plasticity'
    eigenstrain_names = 'thermal_eigenstrain'
  [../]
[]

[Executioner]
  type = Transient
  scheme = bdf2
  solve_type = PJFNK
  line_search = BT

  # Robust solver settings for coupled thermo-mechanics
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type -ksp_type'
  petsc_options_value = 'lu mumps gmres'

  nl_abs_tol = 1e-6
  nl_rel_tol = 1e-4   # 0.01% residual tolerance (standard engineering precision)
  l_max_its = 50      # Allows Krylov iterations to resolve stiff steps
  nl_max_its = 15     # Prevents wasted Newton iterations on bad steps

  dt = 0.1
  end_time = 30.0

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.1
    min_dt = 1e-6
    optimal_iterations = 6
    iteration_window = 2
    growth_factor = 1.25
    cutback_factor = 0.5
  []

  automatic_scaling = true
[]

[Outputs]
  exodus = true
  perf_graph = true
[]
