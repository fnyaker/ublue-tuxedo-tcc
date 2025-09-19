Until official support, this is the repo to go to if you want Tuxedo drivers on your Univeral Blue operating systems (Aurora, Bluefin, Bazzite) for Tuxedo or other Clevo laptops.

It also includes motorcomm yt6801 drivers patched to compile on 6.15+ kernels (thanks to : https://github.com/h4rm00n/yt6801-linux-driver )
### FOR NOW, ONLY AURORA-DX IS PROVIDED
In order to use:
`rpm-ostree rebase ostree-unverified-registry:ghcr.io/fnyaker/tuxedo-aurora-dx`

Secure boot is not tested but due to motorcomm drivers, i d'ont think everything will work with it, feel free to test and raise an issue could be interresting to get it working.
