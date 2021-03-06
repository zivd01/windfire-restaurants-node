# ##### START - Variable section
ANSIBLE_CONFIG_FILE=$1
PLATFORM_OPTION=$2
SSH_PRIVATE_KEY_FILE=aws-key.pem
SSH_CONFIG_FILE=ansible-ssh.cfg
BASTION_IP=
BASTION_HOSTNAME=
USER=ec2-user
HOST=10.0.*.*
# ##### END - Variable section

# ***** START - Function section
createAnsibleConfigFile()
{
	## Create Ansible configuration file 
    echo ${cyn}Creating Ansible configuration file  ...${end}
    cat > deployment/aws/$ANSIBLE_CONFIG_FILE << EOF
[defaults]
private_key_file = $HOME/.ssh/$SSH_PRIVATE_KEY_FILE
host_key_checking = False
[inventory]
enable_plugins = auto, yaml, ini
[ssh_connection]
ssh_args = -C -F $PWD/deployment/aws/$SSH_CONFIG_FILE -o ControlMaster=auto -o ControlPersist=30m
control_path = ~/.ssh/ansible-%%r@%%h:%%p
EOF
    echo ${cyn}Done${end}
    echo
}

createSSHConfigFile()
{
	## Create SSH configuration file for Ansible
    echo "Setting Bastion Host parameters for SSH connection, reading from Terraform state ..."${end}
    case $PLATFORM_OPTION in
        2)  BASTION_IP=$(terraform output -state=../windfire-restaurants-devops/aws/SingleZone/terraform.tfstate bastion-public_ip)
            BASTION_HOSTNAME=$(terraform output -state=../windfire-restaurants-devops/aws/SingleZone/terraform.tfstate bastion-public_dns)
            ;;
        3)  BASTION_IP=$(terraform output -state=../windfire-restaurants-devops/aws/MultiZone/terraform.tfstate bastion-public_ip)
            BASTION_HOSTNAME=$(terraform output -state=../windfire-restaurants-devops/aws/MultiZone/terraform.tfstate bastion-public_dns)
            ;;
		*) 	printf "\n${red}No valid option selected${end}\n"
			printSelectPlatform
			;;
    esac
    echo "Bastion Host IP   =" ${cyn}$BASTION_IP${end}
    echo "Bastion Hostname  =" ${cyn}$BASTION_HOSTNAME${end}
    echo
    echo ${cyn}Creating SSH configuration file for Ansible ...${end}
    cat > deployment/aws/$SSH_CONFIG_FILE << EOF
Host $HOST
ProxyCommand ssh -W %h:%p $USER@$BASTION_IP
IdentityFile ~/.ssh/$SSH_PRIVATE_KEY_FILE

Host $BASTION_IP
Hostname $BASTION_HOSTNAME
User $USER
IdentityFile ~/.ssh/$SSH_PRIVATE_KEY_FILE
ControlMaster auto
ControlPath ~/.ssh/ansible-%r@%h:%p
ControlPersist 5m
EOF
    echo ${cyn}Done${end}
    echo
}

# ##############################################
# #################### MAIN ####################
# ##############################################
createAnsibleConfigFile
createSSHConfigFile