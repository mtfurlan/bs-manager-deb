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

1. github workflow cronjob check if `debsIncludedInThisRepo` has correct debs compared with whatever upstream is (webhooks won't work unless we have control over the source repo, and a daily cronjob seems fine?)
2. if pr needed, download debs into `repo`, generate debian repo there, commit everything but the debs, make PR
3. if the PR looks good, do gpg stuff to make Release.gpg and InRelease, commit to PR
4. approve PR, merge
5. github actions on push to main, do release by downloading debs and trusting that `repo` and `debsIncludedInThisRepo` are in sync (maybe do an error check?), and update the release tag


scripts needed
1. check if debsIncludedInThisRepo is up to date
2. download debs
3. create non-gpg release stuff for debs
4. create PR
5. manual sign gpg
6. update release
