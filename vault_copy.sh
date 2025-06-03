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
    except hvac.exceptions.InvalidPath:
        pass
    return secrets


def read_kv2_secret(client, mount_point, secret_path):
    try:
        return client.secrets.kv.v2.read_secret_version(
            mount_point=mount_point,
            path=secret_path
        )['data']['data']
    except Exception as e:
        print(f"Failed to read {mount_point}/{secret_path}: {e}")
        return None


def create_kv2_engine_if_missing(client, mount_point):
    try:
        mounts = client.sys.list_mounted_secrets_engines()
        if f"{mount_point}/" not in mounts:
            client.sys.enable_secrets_engine(
                backend_type='kv',
                path=mount_point,
                options={'version': '2'}
            )
            print(f"Created KV v2 engine at {mount_point}")
    except Exception as e:
        print(f"Failed to create engine {mount_point}: {e}")


def write_kv2_secret(client, mount_point, path, secret_data):
    try:
        client.secrets.kv.v2.create_or_update_secret(
            mount_point=mount_point,
            path=path,
            secret=secret_data
        )
    except Exception as e:
        print(f"Failed to write {mount_point}/{path}: {e}")


def dump_to_json(data, filename=VALIDATION_FILE):
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"Dumped secrets to {filename}")


def copy_vault_kv2_data(source_url, destination_url, do_write=False):
    src_token = get_token('SOURCE_VAULT_TOKEN', 'SOURCE_VAULT_TOKEN')
    dst_token = get_token('DESTINATION_VAULT_TOKEN', 'DESTINATION_VAULT_TOKEN')
    src_client = get_hvac_client(source_url, src_token)
    dst_client = get_hvac_client(destination_url, dst_token)

    mounts = src_client.sys.list_mounted_secrets_engines()
    copied_data = {}

    for mount_point in mounts:
        mount = mount_point.rstrip('/')
        if mount in EXCLUDED_ENGINES:
            print(f"Skipping excluded engine: {mount}")
            continue

        if is_kv2(src_client, mount):
            print(f"Processing engine: {mount}")
            secrets = list_kv2_secrets(src_client, mount)
            create_kv2_engine_if_missing(dst_client, mount)

            copied_data[mount] = {}
            for secret_path in secrets:
                secret_data = read_kv2_secret(src_client, mount, secret_path)
                if secret_data:
                    copied_data[mount][secret_path] = secret_data
                    if do_write:
                        write_kv2_secret(dst_client, mount, secret_path, secret_data)

    dump_to_json(copied_data)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Vault KVv2 Copier")
    parser.add_argument('--source-url', required=True, help='Source Vault URL')
    parser.add_argument('--destination-url', required=True, help='Destination Vault URL')
    parser.add_argument('--write', action='store_true', help='Write to destination Vault')

    args = parser.parse_args()
    copy_vault_kv2_data(args.source_url, args.destination_url, args.write)
