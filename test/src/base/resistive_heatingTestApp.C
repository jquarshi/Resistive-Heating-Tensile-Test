//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "resistive_heatingTestApp.h"
#include "resistive_heatingApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"

InputParameters
resistive_heatingTestApp::validParams()
{
  InputParameters params = resistive_heatingApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

resistive_heatingTestApp::resistive_heatingTestApp(const InputParameters & parameters) : MooseApp(parameters)
{
  resistive_heatingTestApp::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

resistive_heatingTestApp::~resistive_heatingTestApp() {}

void
resistive_heatingTestApp::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  resistive_heatingApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"resistive_heatingTestApp"});
    Registry::registerActionsTo(af, {"resistive_heatingTestApp"});
  }
}

void
resistive_heatingTestApp::registerApps()
{
  registerApp(resistive_heatingApp);
  registerApp(resistive_heatingTestApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
resistive_heatingTestApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  resistive_heatingTestApp::registerAll(f, af, s);
}
extern "C" void
resistive_heatingTestApp__registerApps()
{
  resistive_heatingTestApp::registerApps();
}
