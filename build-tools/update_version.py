import re
import sys

version = "v0.3.39"

if len(sys.argv) != 2:
    print("Usage: python3 update_version.py <new_release>")
    sys.exit(1)

# Validate input to follow semver scheme
def is_valid_semver(version):
    pattern = re.compile(r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$')
    return bool(pattern.match(version))

if not is_valid_semver(sys.argv[1]):
    print(f"Error: '{sys.argv[1]}' is not a valid semantic version")
    sys.exit(1)

ver=sys.argv[1]



def updateBashUtils(path,ver):
    with open(path, 'r') as file:
        content = file.read()
    
    # Replace the version
    updated_contents = ''
    for line in content.split('\n'):
        if line.strip().startswith('local BASH_UTILS_VERSION='):
            updated_contents += f'    local BASH_UTILS_VERSION="{ver}"\n'
        else:
            updated_contents += line + '\n'
    
    # Write the updated content back to the file
    with open(path, 'w') as file:
        file.write(updated_contents)

def updateVersion(path,ver):
    with open(path, 'r') as f:
        content = f.read()

    old_ver = r'v\d+\.\d+\.\d+'

    content = re.sub(old_ver, ver, content)

    with open(path, 'w') as f:
        f.write(content)

    
change={
    "../bash-utils/bash-utils.sh":updateBashUtils,
    "../scripts/version.sh":updateVersion,
    "./update_version.py":updateVersion,
    "../bip39gen/cmd/version.go":updateVersion,
    "../ipfs-api/types/constants.go":updateVersion,
    "../validator-key-gen/main.go":updateVersion,
    "../validator-key-gen/README.md":updateVersion,
    "../ipfs-api/README.md":updateVersion,
    }

new_release = sys.argv[1]

max_path_length = max(len(path) for path in change.keys())
for path,fn in change.items():
    fn(path, ver)
    print(f"file: \t {path:<{max_path_length + 2}} version changed to {ver}")

print("DONE!")