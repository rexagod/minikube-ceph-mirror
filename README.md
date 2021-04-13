# minikube-ceph-mirror
Sets up a minikube environment for VRO (in ~20m on a Thinkpad T490s). TODOs:
- Setup a release line.
- Automate furthermore (refer [this](https://hackmd.io/@BR-G_swJQCmlyFMwbO4bcw/SyCN53-VO)).

## Prerequisites
- Bash (`^3.x`)
- Minikube (`^1.10` (Configured with `KVM2` driver))
- Libvirt (`latest-stable-release`) and Qemu (`^5.x`)
- Atleast 50G of free space (not meeting this requirement may cause the filesystem to crash)

## Installation
- To setup a dual cluster minikube ceph mirroring environment, just run `./install.sh`.
- To free up all allocated resources and destroy the VRO, pass in the `destroy` option, `./install.sh destroy`.

## Daily usage
- For daily usage purposes, if need be, it's a bit more convenient to create a soft symlink somewhere in your `${PATH}`, like so,
```bash
$ sudo ln -s ~/minikube-ceph-mirror/install.sh /usr/local/bin/vro
$ source .bashrc # (or .zshrc, etc.)
$ vro
```

Stay tuned! More changes coming very soon!
