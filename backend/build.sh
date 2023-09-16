function print_logline {
    echo "[$(date +\"%d-%m-%y\")][$(date +\"%T\")] [backend-build] $1"
}

# function folders_check {
    # if [[ ! -d out ]]; then
        # print_logline "'out/' dir not found."
        # print_logline "Creating 'out/' dir"
        # mkdir out
        # print_logline "'out/' dir successfully created"
    # fi
# }
# 
# folders_check

print_logline "Building Proj"
go build -o build/main cmd/main.go
