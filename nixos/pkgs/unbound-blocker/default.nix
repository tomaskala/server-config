{ buildPythonApplication, setuptools-scm, click, requests }:

buildPythonApplication {
  pname = "unbound-blocker";
  version = "0.1.0";
  src = ../../../src/unbound_blocker;
  format = "pyproject";

  nativeBuildInputs = [ setuptools-scm ];

  propagatedBuildInputs = [ click requests ];
}
