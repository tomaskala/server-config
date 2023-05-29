{ buildPythonApplication, click, requests, black, mypy, ruff, setuptools-scm
, types-requests }:

buildPythonApplication {
  pname = "unbound-blocker";
  version = "0.1.0";
  src = ../../../src/unbound_blocker;
  format = "pyproject";

  nativeBuildInputs = [ black mypy ruff setuptools-scm types-requests ];

  propagatedBuildInputs = [ click requests ];

  preBuild = ''
    black --check --diff .
    mypy --pretty --no-color-output .
    ruff check --no-cache .
  '';
}
