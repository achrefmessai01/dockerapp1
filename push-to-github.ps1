param(
    [string]$remoteUrl
)

if (-not (Test-Path .git)) {
    git init
}

git add .
git commit -m "Initial commit: mon-app + Jenkinsfile + manifests" -q

if (-not $remoteUrl) {
    Write-Host "Specify the remote URL as the first argument, e.g.: .\push-to-github.ps1 https://github.com/you/repo.git"
    exit 1
}

git remote add origin $remoteUrl
git branch -M main
git push -u origin main
