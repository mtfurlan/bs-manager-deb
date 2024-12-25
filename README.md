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

