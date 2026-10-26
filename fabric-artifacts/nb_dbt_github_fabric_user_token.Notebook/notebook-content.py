# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# MARKDOWN ********************

# # Fabric GitHub dbt runner with notebook user token
# Runtime install, GitHub clone, Fabric SQL token, runtime profile, then dbt execution.
# 
# > If the issued user token is not accepted by the Warehouse SQL endpoint, `dbt debug` stops with an authentication/authorization error.


# PARAMETERS CELL ********************

# ---- FABRIC PIPELINE PARAMETERS ----
repo_url = 'https://github.com/MiklosJeneiDezerius/demo_oyster_test.git'
branch = 'main'
dbt_subfolder = 'dbt_oyster_demo_test'
dbt_command = 'build'
dbt_args = ''  # pl. '--select bronze_customer'


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

import os
import sys
import shutil
import shlex
import subprocess
import textwrap
from notebookutils import credentials

# 1. Isolated dbt environment. No notebook-kernel restart.
venv_dir = '/tmp/dbt_venv'
if os.path.exists(venv_dir):
    shutil.rmtree(venv_dir)
print('Creating isolated Python environment...')
subprocess.run([sys.executable, '-m', 'venv', venv_dir], check=True)
venv_python = os.path.join(venv_dir, 'bin', 'python')
dbt_exe = os.path.join(venv_dir, 'bin', 'dbt')
print('Installing dbt-fabric...')
subprocess.run([venv_python, '-m', 'pip', 'install', '--quiet', 'dbt-fabric>=1.11.1'], check=True)

# 2. Clone GitHub repository.
repo_name = repo_url.rstrip('/').split('/')[-1].removesuffix('.git')
repo_dir = f'/home/trusted-service-user/repos/{repo_name}'
if os.path.exists(repo_dir):
    shutil.rmtree(repo_dir)
os.makedirs(os.path.dirname(repo_dir), exist_ok=True)
clone_command = ['git', 'clone', '--depth', '1', '--branch', branch, repo_url, repo_dir]
print('>', ' '.join(clone_command))
subprocess.run(clone_command, check=True)

# 3. Validate dbt project and profile.
dbt_dir = os.path.join(repo_dir, dbt_subfolder)
project_file = os.path.join(dbt_dir, 'dbt_project.yml')
source_profiles_file = os.path.join(dbt_dir, 'profiles.yml')
if not os.path.isfile(project_file):
    raise FileNotFoundError(f'dbt_project.yml not found: {project_file}')
if not os.path.isfile(source_profiles_file):
    raise FileNotFoundError(f'profiles.yml not found: {source_profiles_file}')

# 4. Acquire current Fabric notebook user's SQL token.
print('Acquiring SQL access token from Fabric notebook session...')
sql_token = credentials.getToken('https://database.windows.net/')
if not sql_token:
    raise RuntimeError('Fabric did not return a SQL access token.')
print('SQL access token acquired.')

# 5. Create importable Azure TokenCredential module.
credential_module = os.path.join(dbt_dir, 'fabric_notebook_credential.py')
credential_source = r'''import base64
import json
import os
import time
from azure.core.credentials import AccessToken, TokenCredential

class FabricNotebookCredential(TokenCredential):
    def get_token(self, *scopes, **kwargs):
        token = os.environ.get('FABRIC_SQL_ACCESS_TOKEN')
        if not token:
            raise RuntimeError('FABRIC_SQL_ACCESS_TOKEN is missing.')
        expires_on = int(time.time()) + 3000
        try:
            payload = token.split('.')[1]
            payload += '=' * (-len(payload) % 4)
            expires_on = int(json.loads(base64.urlsafe_b64decode(payload))['exp'])
        except Exception:
            pass
        return AccessToken(token, expires_on)
'''
with open(credential_module, 'w', encoding='utf-8') as f:
    f.write(textwrap.dedent(credential_source).lstrip())

# 6. Copy profiles.yml and change all outputs to token_credential.
runtime_profiles_dir = '/tmp/dbt_profiles'
if os.path.exists(runtime_profiles_dir):
    shutil.rmtree(runtime_profiles_dir)
os.makedirs(runtime_profiles_dir, exist_ok=True)
runtime_profiles_file = os.path.join(runtime_profiles_dir, 'profiles.yml')
profile_builder = '/tmp/prepare_dbt_profile.py'
profile_builder_source = r'''import sys
import yaml
source_file, target_file = sys.argv[1], sys.argv[2]
with open(source_file, 'r', encoding='utf-8') as f:
    profiles = yaml.safe_load(f)
if not isinstance(profiles, dict) or not profiles:
    raise RuntimeError('profiles.yml is empty or invalid')
for profile in profiles.values():
    if not isinstance(profile, dict):
        continue
    for output in profile.get('outputs', {}).values():
        if not isinstance(output, dict):
            continue
        output['authentication'] = 'token_credential'
        output['credential_class'] = 'fabric_notebook_credential.FabricNotebookCredential'
        output['credential_kwargs'] = {}
        for key in ('tenant_id','client_id','client_secret','user','password','token','access_token'):
            output.pop(key, None)
with open(target_file, 'w', encoding='utf-8') as f:
    yaml.safe_dump(profiles, f, sort_keys=False)
'''
with open(profile_builder, 'w', encoding='utf-8') as f:
    f.write(textwrap.dedent(profile_builder_source).lstrip())
subprocess.run([venv_python, profile_builder, source_profiles_file, runtime_profiles_file], check=True)
print(f'Runtime profile created: {runtime_profiles_file}')

# 7. Pass token and custom module only to dbt subprocess.
dbt_environment = os.environ.copy()
dbt_environment['FABRIC_SQL_ACCESS_TOKEN'] = sql_token
existing_pythonpath = dbt_environment.get('PYTHONPATH', '')
dbt_environment['PYTHONPATH'] = dbt_dir if not existing_pythonpath else dbt_dir + os.pathsep + existing_pythonpath

# 8. Run dbt.
def run_dbt(arguments):
    command = [dbt_exe, *arguments, '--project-dir', dbt_dir, '--profiles-dir', runtime_profiles_dir]
    print('>', ' '.join(command))
    subprocess.run(command, check=True, env=dbt_environment)

run_dbt(['debug'])
if any(os.path.isfile(os.path.join(dbt_dir, name)) for name in ('packages.yml', 'dependencies.yml')):
    run_dbt(['deps'])
run_dbt([dbt_command, *shlex.split(dbt_args)])
print('dbt execution completed successfully.')


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }
