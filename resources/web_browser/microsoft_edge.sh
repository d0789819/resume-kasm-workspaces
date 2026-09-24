#!/usr/bin/env bash
set -ex

EDGE_ARGS="--password-store=basic --no-sandbox --disable-gpu --no-first-run"

# Get official stable keyring
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
gpg --dearmor < /tmp/microsoft.asc > /usr/share/keyrings/microsoft-archive-keyring.gpg

# Add Microsoft Edge stable repository to apt sources.list.d
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list
apt-get update
apt-get install -y microsoft-edge-stable
apt-get -f install -y

# Copy desktop files
cp /usr/share/applications/microsoft-edge.desktop $HOME/Desktop
chown 1000:1000 $HOME/Desktop/microsoft-edge.desktop

# Create a wrapper and add custom startup parameters
mv /usr/bin/microsoft-edge /usr/bin/microsoft-edge-orig
cat >/usr/bin/microsoft-edge <<EOL
#!/usr/bin/env bash
/opt/microsoft/msedge/microsoft-edge ${EDGE_ARGS} "\$@"
EOL
chmod +x /usr/bin/microsoft-edge

# Modify Edge .desktop to point to wrapper
if [ -f $HOME/Desktop/microsoft-edge.desktop ]; then
  sed -i -E 's|^Exec=.*|Exec=/usr/bin/microsoft-edge %U|' $HOME/Desktop/microsoft-edge.desktop
fi

# Modify x-www-browser execution mode
sed -i 's@exec -a "$0" "$HERE/microsoft-edge" "$\@"@@g' /usr/bin/x-www-browser
cat >>/usr/bin/x-www-browser <<EOL
exec -a "\$0" "\$HERE/microsoft-edge" "${EDGE_ARGS}" "\$@"
EOL

# Create a default managed policy
mkdir -p /etc/opt/edge/policies/managed
cat >/etc/opt/edge/policies/managed/default_managed_policy.json <<EOL
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false}
EOL

# Vanilla Chrome looks for policies in /etc/opt/chrome/policies/managed which is used by web filtering
# Create a symlink here so filter is applied to Edge as well
mkdir -p /etc/opt/chrome/policies
if [ ! -L /etc/opt/chrome/policies/managed ]; then
  ln -s /etc/opt/edge/policies/managed /etc/opt/chrome/policies/managed
fi
