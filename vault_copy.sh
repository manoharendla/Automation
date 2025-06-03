import os
import json
import getpass
import hvac

EXCLUDED_ENGINES = ['excluded-engine-1', 'excluded-engine-2']  # Add exclusions here
VAULT_NAMESPACE = 'admin'  # Adjust to match your Vault namespace
VALIDATION_FILE = 'vault_secrets_dump.json'


def get_token(env_var_name, label):
    token = os.getenv(env_var_name)
    if not token:
        token = getpass.getpass(f"Enter token for {label}: ")
    return token


def get_hvac_client(url, token):
    return hvac.Client(url=url, token=token, namespace=VAULT_NAMESPACE)


def is_kv2(client, mount_point):
    try:
        engine = client.sys.read_mount_configuration(path=mount_point)
        return engine['data']['options'].get('version') == '2'
    except Exception:
        return False


def list_kv2_secrets(client, mount_point, path=''):
    secrets = []
    try:
        response = client.secrets.kv.v2.list_secrets(mount_point=mount_point, path=path)
        for key in response['data']['keys']:
            if key.endswith('/'):
                secrets.extend(list_kv2_secrets(client, mount_point, f"{path}{key}"))
            else:
                secrets.append(f"{path}{key}")
