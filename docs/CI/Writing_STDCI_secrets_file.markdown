Writing STDCI secrets file
==========================

STDCI uses
[XDG Base Directory Specifications](https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html)
standard in order to search for the secrets file.
The standard defines where different files should be looked
for. **$XDG_CONFIG_HOME** is the place to search for user specific configuration
files. On most systems, this variable is unset by default. For this case,
the standard defines that if **$XDG_CONFIG_HOME** is either not set or empty,
a default equal to **$HOME/.config** should be used.

STDCI searches for a file named `ci_secrets_file.yaml` under **XDG_CONFIG_HOME**.
If **XDG_CONFIG_HOME** is not defined, will look for a file with the same name
under **$HOME/.config**.

`ci_secrets_file.yaml` is a YAML config from the following
form:

    ---
    - name: # Secret name
      project: # Optional. Used to filter secrets by project's name
      branch: # Optional. Used to filter secrets by project's branch name
      # Regex is supported for both project and branch
      # If not specified, the secret will be available for all projects/branches
      secret_data:
        # In this section, we write a key-value pairs of secret data name and
        # it's value. It is used to bind several values for one secret.
        # For example, username and password.


### Example
    ---
    - name: SERVICE_X_CREDENTIALS
      project: my_project
      branch: master
      secret_data:
        username: USERNAME_X
        password: PASSWORD_X

    - name: MY_SSH_KEY
      project: oVirt-.*
      secret_data:
        key: |
          # SSH KEY GOES HERE

Note that **SERVICE_X_CREDENTIALS** will be available to "my_project" only and
only for "master" branch. **MY_SSH_KEY** will be available for all projects that
their name starts with "oVirt-".


