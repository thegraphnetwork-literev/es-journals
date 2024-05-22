![LOGO](/images/logo.png)

# rXiv REST API

A service for rXiv REST API, such as biorxiv and medrxiv

* License: BSD 3 Clause
* Documentation: https://es-journals.github.io

## Features

* The security of our code: Bandit is a powerful tool that we use in our Python
  project to ensure its security. This tool analyzes the code and detects
  potential vulnerabilities. Some of the key features of Bandit are its ease of
  use, its ability to integrate with other tools, and its support for multiple
  Python versions. If you want to know about bandit you can check its
  [documentation](https://bandit.readthedocs.io/en/latest/).

* Finds unused code: [Vulture](https://github.com/jendrikseipp/vulture)
  is useful for cleaning up and finding errors in large code bases in
  Python.

* Complexity of functions and modules: We use
[McCabe](https://github.com/PyCQA/mccabe) to identify the complexity in our
Python code that may be difficult to maintain or understand. By identifying
complex code at the outset, we as developers can refactor it to make it easier
to maintain and understand. In summary, McCabe helps us to improve the quality
of our code and make it easier to maintain. If you would like to learn more
about McCabe and code complexity, you can visit [McCabe - Code Complexity
Checker](https://here-be-pythons.readthedocs.io/en/latest/python/mccabe.html).
This tool is included with [Flake8](https://flake8.pycqa.org/en/latest/).

* Integration with DevOps tools: We use Docker because it allows us to create an
  isolated environment for our application that includes all the necessary
  dependencies, libraries and configurations. This makes it easier to manage and
  reproduce our development and production environments without any conflicts or
  inconsistencies.

  With Docker, we can easily share our application with others and deploy it to
  different environments. This streamlines our development, testing, deployment,
  and collaboration workflows, making the entire process more efficient.
* TODO

## Credits

This package was created with Cookieninja and the
[osl-incubator/scicookie](https://github.com/osl-incubator/scicookie)
project template.
