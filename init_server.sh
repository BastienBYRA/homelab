#!/bin/bash

set -e

user_list=("bastien")

if [ -z "$USER_PASSWORD" ]
then
      echo "Aucun mot de passe défini pour l'utilisateur à créer, défini un mot de passe sous forme de variable d'env sur la machine !"
      exit 1
fi

function create_user() {
  username=$1
  password=$2

  # Créer un utilisateur / mot de passe / home folder
  sudo useradd $username -G docker,ssh_group,sudo
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
  echo "⚠️ Copie cette clé SSH sur ton PC pour pouvoir accéder au serveur :"
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
  echo "➜ Mise à jour la configuration SSHD pour améliorer la sécurité du serveur réussite !"
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

function add_kubeconfig() {
  user=$1
  mkdir /home/$username/.kube
  sudo cp /etc/rancher/k3s/k3s.yaml /home/$user/.kube/config
  sudo chown $user:$user /home/$user/.kube/config
  echo "export KUBECONFIG=/home/$user/.kube/config" >> /home/$user/.bashrc
  fix_owner_folder $username
}

#################################
####### INIT SERVER TOOLS #######
################################# 

# Installe les outils de base
sudo apt-get update
sudo apt-get install -y nano curl git

# Installe Docker
echo "➜ Installation de Docker en cours !"
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
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
echo "➜ Installation de Docker fini !"

# Installe K3S
echo "➜ Installation de K3S en cours !"
curl -sfL https://get.k3s.io | sh -s - \
  --flannel-backend=none \
  --disable-network-policy \
  --disable traefik
echo "➜ Installation de K3S fini !"
echo "⚠️ Copie le Kubeconfig pour pouvoir y accéder depuis ton PC :"
cat /etc/rancher/k3s/k3s.yaml

# Installe Cilium
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

##################################
######## HARDENING SERVER ########
##################################

# Créer un groupe spécial pour les utilisateurs qui pourront SSH sur le serveur
groupadd ssh_group

# Update la configuration du SSHD
hardening_ssh

for user in ${user_list[@]}; do
  # Créer un utilisateur + Configuration autour de l'utilisateur
  echo "➜ Création de l'utilisateur $user en cours !"
  create_user $user $USER_PASSWORD
  generate_sshkey $user
  add_kubeconfig $user
  echo "➜ Création de l'utilisateur $user fini !"
done



