#include "resistive_heatingApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

InputParameters
resistive_heatingApp::validParams()
{
  InputParameters params = MooseApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

resistive_heatingApp::resistive_heatingApp(const InputParameters & parameters) : MooseApp(parameters)
{
  resistive_heatingApp::registerAll(_factory, _action_factory, _syntax);
}

resistive_heatingApp::~resistive_heatingApp() {}

void
resistive_heatingApp::registerAll(Factory & f, ActionFactory & af, Syntax & syntax)
{
  ModulesApp::registerAllObjects<resistive_heatingApp>(f, af, syntax);
  Registry::registerObjectsTo(f, {"resistive_heatingApp"});
  Registry::registerActionsTo(af, {"resistive_heatingApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
resistive_heatingApp::registerApps()
{
  registerApp(resistive_heatingApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
resistive_heatingApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  resistive_heatingApp::registerAll(f, af, s);
}
extern "C" void
resistive_heatingApp__registerApps()
{
  resistive_heatingApp::registerApps();
}
