#!/bin/bash
# backupscript dat wekelijks op zondag 23:00 draait met behoud van 2 versies.
# bron = /opt/stacks
# doel = /opt/backup
set -e

# Instellingen
SOURCE_DIR="/opt/stacks"
BACKUP_DIR="/opt/backup"
SCRIPT_DIR="/opt/scripts"
BACKUP_SCRIPT="$SCRIPT_DIR/backup_stacks.sh"
CRON_FILE="/etc/cron.d/backup_stacks"

# Maak benodigde mappen aan
mkdir -p "$BACKUP_DIR"
mkdir -p "$SCRIPT_DIR"

# Backup-script aanmaken
cat << 'EOF' > "$BACKUP_SCRIPT"
#!/bin/bash
# Pad naar de te back-uppen map
SOURCE_DIR="/opt/stacks"
# Doelmap voor de backups
BACKUP_DIR="/opt/backup"
# Bestandsnaam met datum
BACKUP_FILE="stacks_$(date +'%Y%m%d%H%M').tar.gz"

# Maak de backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" -C "$SOURCE_DIR" .

# Verwijder backups ouder dan 2 weken
find "$BACKUP_DIR" -name "stacks_*.tar.gz" -type f -mtime +14 -exec rm -f {} \;

# Houd alleen de laatste 2 backups
cd "$BACKUP_DIR"
ls -t stacks_*.tar.gz | sed -e '1,2d' | xargs -I {} rm -f {}
EOF

chmod +x "$BACKUP_SCRIPT"

# Cronjob instellen
cat << EOF > "$CRON_FILE"
# Backup stacks elke zondag om 23:00 uur
0 23 * * 0 root $BACKUP_SCRIPT
EOF

# Herlaad cron om nieuwe job te laden
systemctl reload cron

echo "✅ Backup-script en cronjob zijn succesvol ingesteld."
