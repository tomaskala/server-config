{ python3Packages, ruff }:

python3Packages.buildPythonApplication {
  pname = "unbound-blocker";
  version = "0.1.0";
  src = ../../../src/unbound_blocker;
  format = "pyproject";

  nativeBuildInputs = with python3Packages; [ black mypy ruff setuptools-scm types-requests ];

  propagatedBuildInputs = with python3Packages; [ click requests ];

  preBuild = ''
    black --check --diff .
    mypy --pretty --no-color-output .
    ruff check --no-cache .
  '';
}
