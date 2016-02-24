#!/usr/bin/env bats
load test_helper


setup() {
    clean_storage || true
}

@test "info help by arg" {
    run serverauditor info --help
    [ "$status" -eq 0 ]
}

@test "info help command" {
    run serverauditor help info
    [ "$status" -eq 0 ]
}

@test "info host use default formatter" {
    host=$(serverauditor host -L test --port 2022 --address localhost --username root --password password)
    run serverauditor info $host
    [ "$status" -eq 0 ]
}

@test "info host use ssh formatter" {
    host=$(serverauditor host -L test --port 2022 --address localhost --username root --password password)
    run serverauditor info $host -f ssh
    [ "$status" -eq 0 ]
}

@test "info host use ssh formatter with exta options" {
    host=$(serverauditor host -L test --strict-host-key-check yes --keep-alive-packages 20 --timeout 100 --use-ssh-key no --port 2022 --address localhost --username root --password password)
    serverauditor settings --agent-forwarding yes
    run serverauditor info $host -f ssh
    echo ${lines[*]} >&2
    cat ~/.serverauditor/storage | jq . >&2
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "ssh -p 2022 -o StrictHostKeyChecking=yes -o IdentitiesOnly=no -o ServerAliveInterval=100 -o ServerAliveCountMax=20 -o ForwardAgent=yes localhost" ]
}

@test "info host use ssh formatter with exta options disable agent forwarding" {
    host=$(serverauditor host -L test --strict-host-key-check yes --keep-alive-packages 20 --timeout 100 --use-ssh-key no --port 2022 --address localhost --username root --password password)
    serverauditor settings --agent-forwarding no
    run serverauditor info $host -f ssh
    echo ${lines[*]} >&2
    cat ~/.serverauditor/storage | jq . >&2
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "ssh -p 2022 -o StrictHostKeyChecking=yes -o IdentitiesOnly=no -o ServerAliveInterval=100 -o ServerAliveCountMax=20 -o ForwardAgent=no localhost" ]
}
@test "info group use default formatter" {
    group=$(serverauditor group -L test --port 2022)
    run serverauditor info --group $group --debug
    [ "$status" -eq 0 ]
}

@test "info group use ssh formatter" {
    group=$(serverauditor group -L test --port 2022)
    run serverauditor info --group $group -f ssh
    [ "$status" -eq 0 ]
}

@test "info host in 2 groups" {
    serverauditor settings --agent-forwarding yes
    grandgroup=$(serverauditor group -L test --port 22)
    group=$(serverauditor group --parent-group $grandgroup -L test --port 2022)
    host=$(serverauditor host --group $group --address localhost -L test)
    run serverauditor info $host -f ssh
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "ssh -p 2022 -o ForwardAgent=yes localhost" ]
}

@test "info host in 2 groups without agent forwarding" {
    serverauditor settings --agent-forwarding no
    grandgroup=$(serverauditor group -L test --port 22)
    group=$(serverauditor group --parent-group $grandgroup -L test --port 2022)
    host=$(serverauditor host --group $group --address localhost -L test)
    run serverauditor info $host -f ssh
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "ssh -p 2022 -o ForwardAgent=no localhost" ]
}

@test "info host in 2 groups with visible ssh identity" {
    serverauditor settings --agent-forwarding yes
    ssh_identity=$(serverauditor identity --username user)
    grandgroup=$(serverauditor group -L test --port 22 --ssh-identity $ssh_identity)
    group=$(serverauditor group --parent-group $grandgroup -L test --port 2022 --username local)
    host=$(serverauditor host --group $group --address localhost -L test --username root)
    run serverauditor info $host -f ssh --debug
    echo "${lines[*]}" >&2
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "ssh -p 2022 -o ForwardAgent=yes user@localhost" ]
}

@test "info host in 2 groups with visible ssh identity without agent forwarding" {
    serverauditor settings --agent-forwarding no
    ssh_identity=$(serverauditor identity --username user)
    grandgroup=$(serverauditor group -L test --port 22 --ssh-identity $ssh_identity)
    group=$(serverauditor group --parent-group $grandgroup -L test --port 2022 --username local)
    host=$(serverauditor host --group $group --address localhost -L test --username root)
    run serverauditor info $host -f ssh --debug
    echo "${lines[*]}" >&2
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "ssh -p 2022 -o ForwardAgent=no user@localhost" ]
}

@test "info host not existed" {
    group=$(serverauditor group -L test --port 2022)
    run serverauditor info $group
    [ "$status" -eq 1 ]
}

@test "info group not existed" {
    host=$(serverauditor host -L test --port 2022 --address localhost --username root --password password)
    run serverauditor info --group $host
    [ "$status" -eq 1 ]
}
