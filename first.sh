#!/bin/bash
set -e

echo "📦 Systeem bijwerken..."
apt update && apt upgrade -y

echo "🛠️ Vereiste pakketten installeren..."
apt install -y \
  curl \
  sudo \
  fail2ban \
  unattended-upgrades \
  screenfetch \
  htop \
  git \
  wget \

echo "🌍 Tijdzone instellen op Europe/Amsterdam..."
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

echo "🔐 Automatische beveiligingsupdates inschakelen..."
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "🐳 Docker repository toevoegen..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "📦 Docker installeren..."
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if id "mark" &>/dev/null; then
  echo "👤 Gebruiker 'mark' bestaat al — overslaan..."
else
  echo "👤 Gebruiker 'mark' wordt aangemaakt..."
  
  # Wachtwoord vragen zonder echo
  read -s -p "Voer een wachtwoord in voor gebruiker mark: " MARK_PASS
  echo
  read -s -p "Herhaal het wachtwoord: " MARK_PASS_CONFIRM
  echo

  # Vergelijk beide invoeren
  if [ "$MARK_PASS" != "$MARK_PASS_CONFIRM" ]; then
    echo "❌ Wachtwoorden komen niet overeen. Script afgebroken."
    exit 1
  fi

  # Gebruiker aanmaken
  useradd -m -s /bin/bash mark
  echo "mark:$MARK_PASS" | chpasswd
  usermod -aG sudo mark
  usermod -aG docker mark
  echo "✅ Gebruiker 'mark' is aangemaakt."
fi

echo "📁 /opt/stacks map aanmaken..."
mkdir -p /opt/stacks
chown mark:mark /opt/stacks

echo "🚨 Fail2Ban activeren..."
systemctl enable fail2ban
systemctl start fail2ban

echo "🐚 screenfetch instellen voor login van alle gebruikers..."
echo '
# screenfetch bij interactieve shell
if [ -t 1 ] && command -v screenfetch >/dev/null 2>&1; then
  screenfetch
fi
' >> /etc/bash.bashrc

echo "🧰 Lazydocker installeren..."
curl -s https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

if [ -f ~/.local/bin/lazydocker ]; then
  mv ~/.local/bin/lazydocker /usr/local/bin/lazydocker
  chmod +x /usr/local/bin/lazydocker
fi

echo "✅ Lazydocker is geïnstalleerd en beschikbaar als 'lazydocker'"

echo "🚀 Docker automatisch laten starten..."
systemctl enable docker

echo "🔐 WireGuard installeren..."
apt install -y wireguard

echo "📂 WireGuard map aanmaken..."
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

echo "⚙️ WireGuard sysctl instellingen toepassen..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# Optioneel: service automatisch starten (zonder configuratie faalt dit, tenzij je al een .conf maakt)
echo "⏱️ WireGuard automatisch starten bij boot (wanneer config bestaat)..."
systemctl enable wg-quick@wg0 || echo "⚠️ Geen configuratie gevonden voor wg0. Starten zal pas werken na configuratie."

echo "ℹ️ WireGuard is geïnstalleerd. Voeg je configuratie toe in /etc/wireguard/wg0.conf"

echo "✅ Voltooid: Docker-server en beveiliging ingesteld."
