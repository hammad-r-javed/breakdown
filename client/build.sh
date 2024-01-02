function print_logline {
    echo "[$(date +\"%d-%m-%y\")][$(date +\"%T\")] [client] $1"
}

function folders_check {
    if [[ ! -d out ]]; then
        print_logline "'out/' dir not found."
        print_logline "creating 'out/' dir"
        mkdir out
        print_logline "'out/' dir successfully created"
    fi
}

folders_check

print_logline "building client proj"
elm make src/login/Login.elm --output out/login.js

cp src/login/login.html out/login.html

elm make src/dashboard/Dashboard.elm --output out/dashboard.js
cp src/dashboard/dashboard.html out/dashboard.html
