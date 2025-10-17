# BSManager Deb

[BSManager](https://github.com/Zagrios/bs-manager) deb build.

## Adding PPA Repository

```bash
curl -fsSL https://raw.githubusercontent.com/silentrald/bs-manager-deb/refs/heads/main/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/bs-manager.gpg
echo "deb [signed-by=/usr/share/keyrings/bs-manager.gpg] https://raw.githubusercontent.com/silentrald/bs-manager-deb/refs/heads/main ./" | sudo tee /etc/apt/sources.list.d/bs-manager.list
sudo apt update
```

## Install

```bash
sudo apt install bs-manager
```

## Uninstall

```bash
sudo apt remove bs-manager
```


## Repo Automation Notes

1. github workflow cronjob check if repo has most recent releases from upstream(`ghapt scan --check`)
2. if more recent debs are released, update repo (`ghapt-scan`) and generate debian repo (`ghapt repoize`), commit everything but the debs, make PR
3. if the PR looks good, do gpg stuff $(`ghapt sign`), commit to PR
4. approve PR, merge
5. github actions on push to main, do release (`ghapt publish`)
