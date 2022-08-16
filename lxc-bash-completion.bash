_lxc_containers_completion(){
    local cur
    local -a toks
    cur="${COMP_WORDS[COMP_CWORD]}"
    toks=( $(  lxc-ls | cut -d ' ' -f 1 | \grep "$cur" ))
    COMPREPLY=( "${toks[@]}" )
    return 0
}

_lxc_stopped_containers_completion(){
    local cur
    local -a toks
    cur="${COMP_WORDS[COMP_CWORD]}"
    toks=( $(  lxc-ls | grep STOPPED | cut -d ' ' -f 1 | \grep "$cur" ))
    COMPREPLY=( "${toks[@]}" )
    return 0
}

_lxc_running_containers_completion(){
    local cur
    local -a toks
    cur="${COMP_WORDS[COMP_CWORD]}"
    toks=( $(  lxc-ls | grep RUNNING | cut -d ' ' -f 1 | \grep "$cur" ))
    COMPREPLY=( "${toks[@]}" )
    return 0
}

_lxc_frozen_containers_completion(){
    local cur
    local -a toks
    cur="${COMP_WORDS[COMP_CWORD]}"
    toks=( $(  lxc-ls | grep FROZEN | cut -d ' ' -f 1 | \grep "$cur" ))
    COMPREPLY=( "${toks[@]}" )
    return 0
}

 _lxc_shutdown(){
    local containerName=$1
    local containerInfo="$(_lxc_validate_containerName $containerName)"
    if [[ "" != "$(echo $containerInfo | grep STOPPED)" ]]
    then
        echo "container $containerName is already stopped"
        echo "$containerInfo"
        exit 1
    fi
    sudo lxc-attach -n $containerName -- poweroff
}

_lxc_get_ip(){
    local containerName=$1
    local result=$(sudo lxc-attach -n $containerName -- ip -4 -o route get 8.8.8.8 | sed 's#.*src \([^ ]*\).*#\1#')
    echo $result
}

 _lxc_validate_containerName(){
        local containerName=$1
        if [[ "" == "$containerName" ]]
        then
            echo "Please pass a container name.."
            _lxc_list_containers
            return 1
        fi
        local containerInfo=$(lxc-ls | \grep $containerName)
        if [[ "" == "$containerInfo" ]]
        then
            echo "Invalid container name: $containerName"
            _lxc_list_containers
            return 1
        fi
        echo $containerInfo
    }

 _lxc_attach_start_if_not_running_and_attach_as(){
    local containerName=$1
    local containerUser=${2:-$(whoami)}
    local containerInfo="$(_lxc_validate_containerName $containerName)"
    if [[ "" == "$containerInfo" ]]
    then
        exit 1
    fi
    if [[ "" == "$(echo $containerInfo | grep -v STOPPED)" ]]
    then
        echo "Starting container: $containerName"
        sudo lxc-start -n $containerName
    fi
    # this has been carefully crafted to work after many iterations. be warned
    sudo lxc-attach -n $containerName  -- /bin/su $containerUser -l -s /bin/bash
}

complete -F _lxc_running_containers_completion -o nospace lxc-stop
alias lxc-stop="sudo lxc-stop -n "

complete -F _lxc_running_containers_completion -o nospace lxc-shutdown
alias lxc-shutdown="_lxc_shutdown "

complete -F _lxc_containers_completion -o nospace lxc-info
alias lxc-info="sudo lxc-info -n "

complete -F _lxc_stopped_containers_completion -o nospace lxc-start
alias lxc-start="sudo lxc-start -n "

alias lxc-ls="sudo lxc-ls -f"

complete -F _lxc_containers_completion -o nospace lxc-ip
alias lxc-ip="_lxc-get-ip"

complete -F _lxc_containers_completion -o nospace lxc-attach
alias lxc-attach="_lxc_attach_start_if_not_running_and_attach_as"

complete -F _lxc_running_containers_completion -o nospace lxc-freeze
alias lxc-freeze="sudo lxc-freeze -n "

complete -F _lxc_frozen_containers_completion -o nospace lxc-unfreeze
alias lxc-unfreeze="sudo lxc-unfreeze -n "