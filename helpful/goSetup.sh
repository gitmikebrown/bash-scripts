


# Download Go tarball to a safe staging directory
sudo wget -P /usr/local/src https://go.dev/dl/go1.25.1.linux-amd64.tar.gz

# Remove any existing Go installation
sudo rm -rf /usr/local/go

# Extract Go into /usr/local
sudo tar -C /usr/local -xzf /usr/local/src/go1.25.1.linux-amd64.tar.gz

# Clean up the tarball
sudo rm /usr/local/src/go1.25.1.linux-amd64.tar.gz

# Add Go to PATH if not already present
grep -qxF 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc || echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Reload shell config
source ~/.bashrc
 #---------------------------------------
