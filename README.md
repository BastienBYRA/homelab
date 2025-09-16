# Homelab
Homelab de Bastien BYRA, un type super cool (je vous l'assure)

# Présentation du projet
Ce projet est composé en plusieurs briques / modules, il assume que la machine serveur sera un `Ubuntu`.

1. Script d'initialisation du serveur
2. Modules Terraform

## Script d'initialisation du serveur
Le rôle du script d'initialisation du serveur `init_server.sh` est d'appliquer des configurations de base sur une nouvelle machine, ainsi que d'installer quelque outils de base (Docker, K3s, Cilium)

Ci-joint ce qui est fait :
- Met à jour les dépendances du serveur et installe `nano curl` et `git`
- Installe Docker
- Installe K3s
- Installe Cilium
- Créer un groupe `ssh_group` qui contient les seuls utilisateur autorisé à se connecter au serveur via SSH
- Modifie la configuration sshd pour plus de sécurité
- Créer les utilisateurs hard-codé dans la variable `user_list`, les ajoutes dans le groupe `ssh_group` et leur ajoute un `kubeconfig`

```bash
$ ./init_server.sh --help

Ce script permet de configurer un serveur Linux, et d'installer Kubernetes (et plus encore)
Lien du projet GitHub pour plus de détail: https://github.com/BastienBYRA/homelab

Variables d'environnements :

    USER_PASSWORD: Mot de passe donné aux utilisateurs défini dans la variable user_list
                   Utilisateur par défaut : bastien
                   Mot de passe par défaut : Aucun, à définir !

    K8S_DISTRIBUTION: Nom de la distribution Kubernetes à installer.
                      Valeur : rke2 (défaut), k3s
```

# TODO
- [ ] Passer de K3s à RKE2
- [ ] Mettre en place un SonarQube
- [ ] Mettre en place un système d'authentification unifié (eg. Authelia, Keycloak, Authentik, Oauth2 Proxy...)
- [ ] Mettre en place un système de déploiement (eg. ArgoCD ou FluxCD)

# A VOIR
- Regarder plus en détail les API Gateway et voir si avec un API Gateway Controller ça bloque les Ingress etc...
