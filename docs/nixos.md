# NixOS

Some notes on NixOS administration, mostly taken from the [official 
docs](https://nixos.org/manual/nixos/stable/).

See the [configuration 
options](https://nixos.org/manual/nixos/stable/options.html) for the list of 
all available NixOS options.

# Installation

## Switching to a new system configuration

The file `/etc/nixos/configuration.nix` contains the current configuration of 
the machine. Whenever a change is made, you should do
```
# nixos-rebuild switch
```
to switch to it. This makes it the default boot configuration, and attempts to 
realize it in the running system.

Alternatively, it is possible to do
```
# nixos-rebuild test
```
to realise the configuration, but not make it the default. In case of errors, 
simply restart the machine to load back the previous configuration.

Finally,
```
# nixos-rebuild boot
```
makes the current configuration the default, but does not switch to it 
immediately. It will be realised upon the next boot.

Additionally, it is possible to test the configuration in a sandbox (assuming 
that the machine supports hardware virtualisation). The following builds and 
launches a QEMU VM with the configuration, forwarding the host port 2222 to the 
guest port 22.
```
# nixos-rebuild build-vm
$ QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-*-vm
```
It may be useful to set
```
users.users.<username>.initialHashedPassword = "test";
```

## Upgrading NixOS

The best way to keep the NixOS installation up to date is to use channels; a 
channel is a Nix mechanism for distributing Nix expressions and binaries. The 
current list of channels can be found at <https://channels.nixos.org/>.

Upon installation, the system is automatically subscribed to the channel 
corresponging to its installation source. To see which NixOS channel you are 
subscribed to, run
```
# nix-channel --list | grep nixos
```

To switch to a different channel, run
```
# nix-channel --add https://nixos.org/channels/<channel-name> nixos
```
substituting the channel name, for example `nixos-22.11-small`. Once the 
channel has been added, switch to its latest version by running
```
# nixos-rebuild switch --upgrade
```
which is quivalent to `nix-channel --update nixos; nixos-rebuild switch`.

Note that channels are set per user; running `nix-channel --add ...` as a 
non-root user will not affect `/etc/nixos/configuration.nix`.

### Automatic upgrades

To keep a system up to date automatically, add the following to 
`/etc/nixos/configuration.nix`:
```
system.autoUpgrade.enable = true;
system.autoUpgrade.allowReboot = true;
```
optionally also setting a channel by adding
```
system.autoUpgrade.channel = https://nixos.org/channels/<channel-name>;
```

This enables a `nixos-upgrade.service` systemd service scheduled using a 
systemd timer (run `systemctl list-timers` to see when). Without `allowReboot`, 
it runs `nixos-rebuild switch --upgrade` like described above. With 
`allowReboot`, it additionally reboots the system if the new generation 
contains different kernel, initrd or kernel modules.

# Configuration

The NixOS configuration file, `/etc/nixos/configuration.nix`, is a Nix 
expression.

## NixOS configuration file

The configuration file looks like this
```
{ config, pkgs, ... }:

{ option definitions
}
```
The first line, `{ config, pkgs, ... }:` denotes that the expression is a 
function that takes at least two arguments, `config` and `pkgs`. The function 
returns a set (`{ ... }`) of option definitions of the form `name = value;`.

NixOS checks the configuration file for correctness; in case of errors, the 
`nixos-rebuild` command fails.

## Modularity

The configuration can be split into multiple files, for example to extract 
common functionality. The `configuration.nix` file might look like this:
```
{ config, pkgs, ...}:

{ imports = [ ./vpn.nix ./kde.nix ];
  services.httpd.enable = true;
  environment.systemPackages = [ pkgs.emacs ];
  ...
}
```
It now imports two other configuration files, `vpn.nix` and `kde.nix`, the 
latter of which might look like
```
{ config, pkgs, ...}:

{ services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  environment.systemPackages = [ pkgs.vim ];
  ...
}
```
Note that both files define the option `environment.systemPackages`; when 
multiple files define the same option, NixOS attempts to merge them. In this 
case, lists are simply concatenated, the values in `configuration.nix` 
appearing last. To make them appear first, the option could be written as 
`environment.systemPackages = mkBefore [ pkgs.emacs ];`.

For other option types, a merge may not be possible. For example, if two 
modules define `services.httpd.adminAddr`, `nixos-rebuild` will throw an error. 
When that happens, it is possible to make one option take precedence over the 
others:
```
services.httpd.adminAddr = pkgs.lib.mkForce "bob@example.org";
```

### The `config` argument

When using multiple modules, it may be necessary to access configuration values 
defined in other modules. That's what the `config` argument is for: it contains 
the complete, merged system configuration (the result of combining the 
configurations returned by every module). For example, the following module 
adds some packages to `environment.systemPackages` only if 
`services.xserver.enable` is set to `true` in some other module:
```
{ config, pkgs, ... }:

{ environment.systemPackages =
    if config.services.xserver.enable then
      [ pkgs.firefox pkgs.thunderbird ]
    else [];
}
```

If there are many modules, it may not be obvious what the final configuration 
option value is. The `nixos-option` command allow to find that out:
```
$ nixos-option services.xserver.enable
true
$ nixos-option boot.kernelModules
[ "tun" "ipv6" "loop" ... ]
```

### REPL

Interactive exploration is also possible using the Nix REPL:
```
$ nix repl '<nixpkgs/nixos>'
nix-repl> config.networking.hostName
"mandark"
nix-repl> map (x: x.hostName) config.services.httpd.virtualHosts
[ "example.org" "example.gov" ]
```

### Generating modules

Finally, modules can be generated using code instead of writing other files. 
The following example sets several options in a `let ... in` block and has the 
same effect as if those options were defined in another file.
```
{ config, pkgs, ...}:

let netConfig = hostName: {
  networking.hostName = hostName;
  networking.useDHCP = false;
};

in

{ imports = [ (netConfig "nixos.localdomain") ]; }
```

## Package management

There are two distinct styles of package management:
* Declarative: The desired packages are specified in `configuration.nix`. Upon 
  every `nixos-rebuild`, NixOS will ensure that you get a consistent set of 
  binares corresponding to the specification.
* Ad hoc: The packages are installed and uninstalled via the `nix-env` command. 
  This style allows mixing packages from different nixpkgs versions. It is also 
  the only way of package management for non-root users.

### Declarative package management

The desired pacakges are specified using the `environment.systemPackages` 
option in `configuration.nix`. For example, the following enables Mozilla 
Thunderbird:
```
environment.systemPackages = [ pkgs.thunderbird ];
```
This specification has the effect of building or downloading the Thunderbird 
package once `nixos-rebuild switch` is run.

The list of available packages can be obtained as follows, the first column 
being the attribute name:
```
$ nix-env -qaP '*' --description
nixos.firefox   firefox-23.0   Mozilla Firefox - the browser, reloaded
...
```
The `nixos` prefix tells us that we want to get the package from the `nixos` 
channel, and only works for the CLI tools. For declarative configuration, use 
the `pkgs` prefix.

To uninstall a package, simply remove it from the `environment.systemPackages` 
option and run `nixos-rebuild switch`.

#### Customizing packages

It is possible to customize a package in almost arbitrary ways, such as 
changing or disabling its dependencies. The `emacs` package in nixpkgs is by 
default built against GTK 2. To instead build it against GTK 3, specify the 
following:
```
environment.systemPackages = [ (pkgs.emacs.override { gtk = pkgs.gtk3; }) ];
```
The function `override` performs the call to the Nix function that produces 
Emacs, with the original arguments amended by those specified. The surrounding 
parentheses are necessary, because function application binds more weakly than 
list construction (without them, we would get a list of two elements).

Even greater customization is possible using the function `overrideAttrs`. 
While the `override` function overrides the arguments of a package function, 
`overrideAttrs` changes the attributes passed to `mkDerivation`. This has the 
potential of changing any aspect of the package, such as its source code. For 
example, to override the Emacs source code, specify
```
environment.systemPackages = [
  (pkgs.emacs.overrideAttrs (oldAttrs: {
    name = "emacs-25.0-pre";
    src = /path/to/my/emacs/tree;
  }))
];
```
Here, `overrideAttrs` takes the Nix derivation specified by `pkgs.emacs` and 
produces a new derivation in which the `name` and `src` attributes have been 
replaced by the given values by re-calling `stdenv.mkDerivation`. The original 
attributes are accessible from the `oldAttrs` function argument.

Such overrides are not global, they do not affect the original package. Other 
packages in nixpkgs continue to depend on the original version of the modified 
package. To make everything depend on the modified version, apply a global 
override as follows:
```
nixpkgs.config.packageOverrides = pkgs:
  { emacs = pkgs.emacs.override { gtk = pkgs.gtk3; };
  };
```
This has the effect equivalent to modifying the `emacs` attribute in the 
nixpkgs source tree.

#### Adding custom packages

If a package you need is not available in NixOS, you can package it with Nix.

One option is to clone the nixpkgs repository, add the package to this clone, 
and optionally submit a patch or a pull request to have it accepted to the main 
nixpkgs repository. This is described in the [nixpkgs 
manual](https://nixos.org/manual/nixpkgs/stable/) in more detail.

The second possibility is to add the package outside of the nixpkgs tree. The 
following is how to specify a build of GNU Hello directly in 
`configuration.nix`.
```
environment.systemPackages =
  let
    my-hello = with pkgs; stdenv.mkDerivation rec {
      name = "hello-2.8";
      src = fetchurl {
        url = "mirror://gnu/hello/${name}.tar.gz";
        sha256 = "0wqd8sjmxfskrflaxywc7gqw7sfawrfvdxd9skxawzfgyy0pzdz6";
      };
    };
  in
    [ my-hello ];
```
This could of course be moved to a separate Nix expression and importing it:
```
environment.systemPackages = [ (import ./my-hello.nix) ];
```
where `my-hello.nix` contains
```
with import <nixpkgs> {};  # Bring all of nixpkgs into scope.

stdenv.mkDerivation rec {
  name = "hello-2.8";
  src = fetchurl {
    url = "mirror://gnu/hello/${name}.tar.gz";
    sha256 = "0wqd8sjmxfskrflaxywc7gqw7sfawrfvdxd9skxawzfgyy0pzdz6";
  };
}
```
The latter approach allows testing the package easily:
```
$ nix-build my-hello.nix
$ ./result/bin/hello
Hello, world!
```

### Ad hoc package management

Packages can be installed and uninstalled from the command line with the 
`nix-env` command. For instance, to install Mozilla Thunderbird:
```
$ nix-env -iA nixos.thunderbird
```
If you invoke this as root, the packages will be installed into the Nix profile 
`/nix/var/nix/profiles/default` and made visible to all users. Otherwise, the 
package ends up in `/nix/var/nix/profiles/per-user/<username>/profile` and 
will not be visible to other users. The `-A` flag specifies the package by its 
attribute name; without it, the package is installed by matching against its 
package name (`thunderbird` in this case). The latter is (much!) slower, 
because it requires matching against all available Nix packages, and is 
ambiguous in case of multiple matches.

Packages come from the NixOS channel. To update a package, first update to the 
latest version of the NixOS channel:
```
$ nix-channel --update nixos
```
and then run the `nix-env -iA` command again. Other packages are not affected, 
as opposed to the declarative approach, where running `nixos-rebuild switch` 
causes all packages to be updated to their latest versions. However, all 
packages can be updated by
```
$ nix-env -u '*'
```

A package can be uninstalled with the `-e` flag:
```
$ nix-env -e thunderbird
```

Finally, to rollback an undsirable Nix action, run
```
$ nix-env --rollback
```

# Administration

## Cleaning the Nix store

Nix has a purely functional model, meaning that packages are never updated in 
place. Instead, new package versions end up in a different location in the Nix 
store (`/nix/store`). You should periodically run the Nix garbage collector to 
remove old, unreferenced packages:
```
$ nix-collect-garbage
```

Alternatively, you can start a systemd service to collect garbage in 
background:
```
# systemctl start nix-gc.service
```
This unit can be run automatically at certain points in time, for instance 
every day at 03:15, by adding the following to `configuration.nix`:
```
nix.gc.automatic = true;
nix.gc.dates = "03:15";
```

The above commands do not remove garbage collector roots, such as old system 
configurations; they only remove unreferenced packages. As such, they do not 
prevent rolling back to a previous system configuration. The following command 
removes old roots, removing the ability to roll back to them.
```
$ nix-collect-garbage -d
```

Another option to reclaim disk space is to run the Nix store optimiser, which 
replaces identical files in the nix store by hard links to a single copy:
```
$ nix-store --optimise
```

If the `/boot` partition runs out of space after cleaning old profiles, run 
either `nixos-rebuild boot` or `nixos-rebuild switch` to update the `/boot` 
partition and clear space.
