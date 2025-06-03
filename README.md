# Automation
Running expect in debug mode :
exp_internal at the top 

exp_internal 1


exect eof to close the expect script or use exit 0

# Vault KVv2 Secrets Copier

A Python script to copy all secrets from KV v2 engines in one HashiCorp Vault instance to another, preserving secret structure, with support for:

- Inclusion and exclusion lists for specific KV engines
- Creating destination KV v2 engines if they do not exist
- Reading tokens from environment variables or prompting securely
- Optional write to destination (dry-run by default)
- JSON dump of copied secrets for validation

---

## 🔧 Requirements

- Python 3.7+
- [`hvac`](https://pypi.org/project/hvac/)

Install dependencies:

```bash
pip install hvac
```

## Usage
```bash
python vault_copy.py --source-url <SOURCE_VAULT_URL> --destination-url <DEST_VAULT_URL> [--write]
```



