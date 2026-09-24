#!/usr/bin/env bash
set -ex

CHROME_ARGS="--password-store=basic --no-sandbox --disable-gpu --no-first-run"

# Remove old Chromium-related packages
apt-get update
apt-get remove -y chromium-browser-l10n chromium-codecs-ffmpeg chromium-browser

wget -P /tmp https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y /tmp/google-chrome-stable_current_amd64.deb
apt-get -f install -y

# Copy desktop files
sed -i 's/-stable//g' /usr/share/applications/google-chrome.desktop
cp /usr/share/applications/google-chrome.desktop $HOME/Desktop
chown 1000:1000 $HOME/Desktop/google-chrome.desktop

# Create a wrapper and add custom startup parameters
mv /usr/bin/google-chrome /usr/bin/google-chrome-orig
cat >/usr/bin/google-chrome <<EOL
#!/usr/bin/env bash
/opt/google/chrome/google-chrome ${CHROME_ARGS} "\$@"
EOL
chmod +x /usr/bin/google-chrome
cp /usr/bin/google-chrome /usr/bin/chrome

# Modify x-www-browser execution mode
sed -i 's@exec -a "$0" "$HERE/chrome" "$\@"@@g' /usr/bin/x-www-browser
cat >>/usr/bin/x-www-browser <<EOL
exec -a "\$0" "\$HERE/chrome" "${CHROME_ARGS}" "\$@"
EOL

# Create a default managed policy
mkdir -p /etc/opt/chrome/policies/managed
cat >/etc/opt/chrome/policies/managed/default_managed_policy.json <<EOL
{"CommandLineFlagSecurityWarningsEnabled": false, "DefaultBrowserSettingEnabled": false}
EOL
