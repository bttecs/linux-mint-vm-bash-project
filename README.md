# Linux Mint VM Bash Project

GitHub-ready project for the Linux Mint virtual machine and Bash scripting exercises.

## Project Contents

- `scripts/check-linux-mint.sh` - Exercise 1 Linux Mint system checks
- `scripts/install-java.sh` - Exercise 2 Java install and version validation
- `scripts/user-processes.sh` - Exercise 3 current user process list
- `scripts/user-processes-sorted.sh` - Exercise 4 process sorting by memory or CPU
- `scripts/user-processes-limited.sh` - Exercise 5 sorted process list with row limit
- `scripts/start-node-app.sh` - Exercises 6-9 Node app install, start, status, logs, and service user
- `tests/run-tests.sh` - local Bash tests
- `.github/workflows/ci.yml` - GitHub Actions CI

## Exercise 1: Linux Mint Virtual Machine

Create a Linux Mint VM in VirtualBox, open a terminal, then run:

```bash
chmod +x scripts/check-linux-mint.sh
./scripts/check-linux-mint.sh
```

The script checks:

- Linux distribution from `/etc/os-release`
- Package managers: `apt`, `apt-get`, and `yum`
- CLI editors: `nano`, `vi`, and `vim`
- Software manager: `mintinstall`
- Current user's shell from `/etc/passwd`

Expected Linux Mint facts:

- Distribution: Linux Mint
- Package manager: `apt` / `apt-get`
- Software manager: Software Manager, provided by `mintinstall`
- Common shell: `/bin/bash`
- Common CLI editors: Nano is usually available; Vim may need installation

## Exercise 2: Install Java

Run this inside the Linux Mint VM:

```bash
chmod +x scripts/install-java.sh
./scripts/install-java.sh
```

The script installs Java using the detected package manager and then checks:

1. Java is not installed
2. Java is installed but lower than version 11
3. Java 11 or higher is installed successfully

The version parsing uses `awk`, including this pattern:

```bash
awk -F '"' 'NR == 1 {print $2}'
```

## Exercises 3-5: User Processes

Exercise 3:

```bash
chmod +x scripts/user-processes.sh
./scripts/user-processes.sh
```

Exercise 4:

```bash
chmod +x scripts/user-processes-sorted.sh
./scripts/user-processes-sorted.sh
```

Enter `memory` or `cpu` when prompted.

Exercise 5:

```bash
chmod +x scripts/user-processes-limited.sh
./scripts/user-processes-limited.sh
```

Enter the sort option and how many process rows to print.

## Exercises 6-9: Start Node App

Run this inside the Linux Mint VM:

```bash
chmod +x scripts/start-node-app.sh
sudo ./scripts/start-node-app.sh app-logs
```

The script:

- Installs NodeJS and NPM
- Downloads the artifact from the provided S3 URL
- Extracts the app
- Sets `APP_ENV=dev`, `DB_USER=myuser`, and `DB_PWD=mysecret`
- Creates and sets `LOG_DIR`
- Creates a service user named `myapp`
- Runs the app as `myapp` in the background
- Prints the running process and listening port

Check the app log:

```bash
cat app-logs/app.log
```

## Run Tests

From the project root:

```bash
bash tests/run-tests.sh
```

The tests perform syntax checks and mock the Java/process commands. They do not install packages, download the Node artifact, create users, or start services.

## Publish To GitHub

Create an empty GitHub repository, then from this folder run:

```bash
git init
git add .
git status
git commit -m "Add Linux Mint VM Bash exercises"
git branch -M main
git remote add origin git@github.com:YOUR_USERNAME/linux-mint-vm-bash-project.git
git push -u origin main
```

Only run the commit and push commands after reviewing the files.
