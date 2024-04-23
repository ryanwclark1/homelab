# Define the user for the SSH connections
USER=root

# List of hosts
declare -a HOSTS=("james.techcasa.io" "andrew.techcasa.io" "john.techcasa.io" "peter.techcasa.io" "judas.techcasa.io" "philip.techcasa.io")

# SSH Key File
SSH_KEY="$HOME/.ssh/id_rsa"

# Generate SSH key if it doesn't exist
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_KEY" -N ""
    echo "SSH key generated."
else
    echo "SSH key already exists."
fi

# Copy SSH public key to each host
for HOST in "${HOSTS[@]}"; do
    echo "Copying SSH public key to $HOST..."
    ssh-copy-id -i "${SSH_KEY}.pub" "$USER@$HOST"
done

echo "SSH setup complete."