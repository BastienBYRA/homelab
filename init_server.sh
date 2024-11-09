#!/bin/bash

set -e

if [ -z "$USER_PASSWORD" ]
then
      echo "Aucun mot de passe défini pour l'utilisateur à créer, défini un mot de passe sous forme de variable d'env sur la machine !"
      exit 1
fi

function create_user() {
  username=$1
  password=$2

  # Créer un utilisateur / mot de passe / home folder
  sudo useradd $username -G docker, ssh_group, sudo
  echo $username:$password | chpasswd         # Ajoute un mot de passe
  sudo usermod --shell /bin/bash $password         # Défini bash comme le shell par défaut
  mkdir /home/$username                       # Génère le dossier home de l'utilisateur
  fix_owner_folder $username
}

function generate_sshkey() {
  username=$1
  mkdir /home/$username/.ssh/
  touch /home/$username/.ssh/authorized_keys

  ssh-keygen -t ed25519 -a 100 -o -N "" -q -f ./generate_key       # https://stackoverflow.com/questions/3659602/automating-enter-keypresses-for-bash-script-generating-ssh-keys
  cat generate_key.pub >> /home/$username/.ssh/authorized_keys

  # C'est pas ouf niveau sécurité, mais vu que je lance ce script moi-même sur mon PC, c'est acceptable.
  echo "Copie cette clé SSH sur ton PC :"
  cat ./generate_key

  rm -f ./generate_key ./generate_key.pub

  fix_owner_folder $username
}

# Les opérations de créations/installations/modifications sont fait avec un compte root,
# cette fonction à pour but d'assurer que tout ce qui est dans le dossier de l'utilisateur
# est modifiable par l'utilisateur.
function fix_owner_folder() {
  username=$1
  chown -R $username:$username /home/$username/
}

function hardening_ssh() {
  sshd_config=/etc/ssh/sshd_config

  # Desactive authentification directement avec root et sans password
  update_or_add_config PermitEmptyPasswords no $sshd_config
  update_or_add_config PermitRootLogin no $sshd_config

  # Pour désactiver l'authentification username/password
  update_or_add_config PasswordAuthentication no $sshd_config
  update_or_add_config ChallengeResponseAuthentication no $sshd_config
  update_or_add_config UsePAM no $sshd_config

  # Forcer l'authentification avec clé SSH
  update_or_add_config PubkeyAuthentication yes $sshd_config

  # Autoriser uniquement certains utilisateur a se connecter via SSH
  update_or_add_config AllowGroups ssh_group $sshd_config
}

# Fonction pour vérifier, modifier ou ajouter une configuration
update_or_add_config() {
    key="$1"
    value="$2"
    config_file="$3"

    if grep -q "^${key}" "$sshd_config"; then
        # Si la configuration existe, la modifier avec sed
        sed -i "s|^${key}.*|${key} ${value}|" "$sshd_config"
    else
        # Si la configuration n'existe pas, l'ajouter à la fin
        echo "${key} ${value}" >> "$sshd_config"
    fi
}

#################################
####### INIT SERVER TOOLS #######
################################# 

# Installe Docker
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Installe K3S
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy --disable "traefik"' sh -

##################################
######## HARDENING SERVER ########
##################################

# Créer un groupe spécial pour les utilisateur qui pourront SSH sur le serveur
groupadd ssh_group

# Créer un utilisateur + Configuration autour de l'utilisateur
create_user bastien $USER_PASSWORD
generate_sshkey bastien

# Modifie la configuration SSH pour le rendre plus strict
hardening_ssh

