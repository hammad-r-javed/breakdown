function print_logline {
    echo "[$(date +\"%d-%m-%y\")][$(date +\"%T\")] [client] $1"
}

function folders_check {
    if [[ ! -d out ]]; then
        print_logline "'out/' dir not found."
        print_logline "Creating 'out/' dir"
        mkdir out
        print_logline "'out/' dir successfully created"
    fi
}

folders_check

print_logline "Building Proj"
elm make src/login_page/Login.elm --output out/login.js
cp src/login_page/login.html out/login.html
