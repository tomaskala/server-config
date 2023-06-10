# NixOps

Notes from the excellent 
[presentation](https://www.youtube.com/watch?v=SoHtccHNOJ8) by Kim Lindberger.

It seems that NixOps has since been updated? AWS support might have been moved 
to plugins. Encrypted links support has been dropped and _might_ have been 
moved to a plugin as well.

## What does it do?

* Deploys NixOS system configuration to remote machines.
* The entire configuration is built on the local machine before being copied 
  to the remote machines.
* In case of configuration errors, the whole operation is aborted.
* The state is tracked in a local SQLite database.
* The following NixOS configuration to start nginx hosting NixOS manual 
  (`webserver.nix`)
  ```
  { config, pkgs, ... }:

  {
    services.nginx.enable = true;
    services.nginx.virtualHosts."example" = {
      locations."/" = {
        root = "${config.system.build.manual.manualHTML}/share/doc/nixos";
      };
    };
  }
  ```
  gets turned into
  ```
  {
    webserver =
      { config, pkgs, ... }:

      {
        deployment.targetHost = "1.2.3.4";

        services.nginx.enable = true;
        services.nginx.virtualHosts."example" = {
          locations."/" = {
            root = "${config.system.build.manual.manualHTML}/share/doc/nixos";
          };
        };
      }
  }
  ```

## Creating a deployment

* To use this configuration, we need to tell NixOps about it by creating a 
  deployment:
  ```
  $ nixops create -d <deployment-name> <deployment-file(s)>
  ```
  This will create a deployment, but not actually deploy anything. It only has 
  to be done once.
  * Specifically:
    ```
    $ nixops create -d demo webserver.nix
    $ nixops info -d demo
    ```

## Deploying

* To deploy an existing configuration, run
  ```
  $ nixops deploy -d <deployment-name>
  ```
  * Specifically:
    ```
    $ nixops deploy -d demo
    ```
* This must be done every time we make a change to our configuration.
* During deployment, NixOps performs the following tasks:
  1. Check state to see whether all declared resources have been provisioned.
  2. If a resource is missing, it is provisioned.
    * In the case of a machine, it gets instantiated and NixOps waits for SSH 
      access to the machine.
  3. The configuration is built and its closure gets copied to the server.
  4. The configuration gets activated.

## Split deployments

* We can split the physical specification (the deployment information) and the 
  logical specification (the machine configuration) into as many files as we 
  want. They will get merged together into a single specification.
  * `webserver_logical.nix`:
    ```
    {
      webserver =
        { config, pkgs, ... }:

        {
          services.nginx.enable = true;
          services.nginx.virtualHosts."example" = {
            locations."/" = {
              root = "${config.system.build.manual.manualHTML}/share/doc/nixos";
            };
          };
        }
    ```
  * `webserver_physical.nix`:
    ```
    {
      webserver =
        { resources, ... }:

        {
          deployment.targetHost = "1.2.3.4";
        };
    }
    ```
* We just have to tell NixOps about both files when creating a deployment:
  ```
  $ nixops create -d demo webserver_logical.nix webserver_physical.nix
  ```
* We can reuse the same logical specification in multiple deployments:
  ```
  $ nixops create -d testing webserver_logical.nix webserver_physical_testing.nix
  $ nixops create -d production webserver_logical.nix webserver_physical_production.nix
  ```
* Since it's all Nix, we can also reuse any host specification within a 
  deployment:
  * `webserver_logical.nix`
    ```
    let
      webserver =
        { config, pkgs, ... }:

        {
          services.nginx.enable = true;
          ...
        };
    in {
      webserver1 = webserver;
      webserver2 = webserver;
    }
    ```

## Communication between hosts

* Hosts in a deployment can refer to each other by name, because NixOps updates 
  the `/etc/hosts` file.
* If we wanted to put haproxy in front of our webservers, the config would look 
  like this:
  ```
  backend site
    server server1 webserver1:80 check send-proxy
    server server2 webserver2:80 check send-proxy
  ```
* We can also let NixOps set up encrypted tunnels to the specified hosts by 
  setting `deployment.encryptedLinksTo`:
  * `load_balancer_logical.nix`:
    ```
    deployment.encryptedLinksTo = [ "webserver1" "webserver2" ];

    services.haproxy.enable = true;
    services.haproxy.config = ''
      ...
      backend site
        server server1 webserver1-encrypted:80 check send-proxy
        server server2 webserver2-encrypted:80 check send-proxy
    '';
    ```

## Handling secrets

* Specifying secrets as regular strings is a bad idea, because they will be put 
  into the world-readable Nix store.
  ```
  services.gitlab.databasePassword = "1234";  # World-readable.
  ```
* Instead, we often use paths to files outside the Nix store which contain the 
  secrets:
  ```
  services.gitlab.databasePasswordFile = "/var/lib/gitlab_db_pw";
  ```
* Each NixOps deployment can define a special attribute set called 
  `deployment.keys` where each attribute corresponds to a file to be placed 
  outside the Nix store on the target hosts:
  * `webserver_logical.nix`:
    ```
    services.nginx.virtualHosts."example" = {
      forceSSL = true;
      sslCertificate = config.deployment.keys.ssl_cert.path;
      sslCertificateKey = config.deployment.keys.ssl_cert.path;
      ...
    };

    # The secrets are by default owned by root and readable by the keys group.
    users.users.nginx.extraGroups = [ "keys" ];

    deployment.keys.ssl_cert = {
      keyFile = ./secrets/ssl_cert_key_bundle;  # This is the local path.
      permissions = "0600";
    };
    ```

## Example

* Set up a deployment with two webservers and a load balancer.
  * The webservers share the same logical and physical specification.
  * The load balancer uses the same physical specification as the webservers.
  * The load balancer communicates with the webservers over encrypted tunnels.
  * It's all deployed to a new VPC on AWS.
* `webserver_logical.nix`:
  ```
  let
    webserver =
      { config, pkgs, ... }:

      {
        services.nginx.enable = true;
        services.nginx.virtualHosts."example" = {
          listen = [
            {
              addr = "0.0.0.0";
              extraParameters = [ "proxy_protocol" ];
            }
          ];

          locations."/" = {
            root = "${config.system.build.manual.manualHTML}/share/doc/nixos";
          };
        };

        networking.firewall.allowedTCPPorts = [ 80 ];
      };

    loadBalancer =
      { config, pkgs, ... }:

      {
        deployment.keys = {
          ssl_cert = {
            keyFile = /home/user/repos/server-setup/secrets/ssl/wildcard_2019.certificate_private_key_bundle.pem;
            permissions = "0600";
          };
        };

        deployment.encryptedLinksTo = [ "webserver1" "webserver2" ];

        services.haproxy.enable = true;
        services.haproxy.config = ''
          global
            # From https://ssl-config.mozilla.org
            # Modern config as of Feb 2020 - update it from the link above!
            ssl-defaults-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
            ssl-defaults-bind-options no-sslv3 no-tlsv10 no-tlsv11 no-tlsv12 no-tls-tickets

            ssl-default-server-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA383:TLS_CHACHA20_POLY1305_SHA256
            ssl-default-server-options no-sslv3 no-tlsv10 no-tlsv11 no-tlsv12 no-tls-tickets

          defaults
            mode http

          frontend public
            bind :443 ssl crt ${config.deployment.keys.ssl_cert.path} alpn h2,http/1.1

            # Redirect http -> https
            bind :80
            redirect scheme https code 301 if ! { ssl_fc }

            # HSTS (15768000 seconds = 6 months)
            http response set header Strict-Transport-Security max-age=15768000

            use_backend site

        backend site
          server webserver1 webserver1-encrypted:80 check send-proxy
          server webserver2 webserver2-encrypted:80 check send-proxy
        '';

        users.users.haproxy.extraGroups = [ "keys" ];

        networking.firewall.allowedTCPPorts = [ 80 443 ];
      };
  in {
    webserver1 = webserver;
    webserver2 = webserver;
    inherit loadBalancer;
  };
  ```
* `webserver_physical_production_redacted.nix`:
  ```
  let
    accessKeyId = "XXXXXXXXXXXXXXXXXXXX";  # Symbolic name looked up in ~/.aws/credentials
    region = "eu-north-1";
    php-host =
      { resources, lib, ... }:

      {
        deployment.targetEnv = "ec2";

        deployment.ec2 = {
          inherit accessKeyId region;
          ami = "ami-98a9ab98abobc";
          instanceType = "t3.small";
          ebsInitialRootDiskSize = 10;

          securityGroupIds = with resources.ec2SecurityGroups; [
            public-http-sg.name
            public-ssh-sg.name
          ];
          associatePublicIpAddress = true;
          subnetId = resources.vpcSubnets.example-subnet;

          keyPair = resources.ec2KeyPairs.stockholm;
        };

        boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
      };
  in {
    resources = {
      ec2KeyPairs = {
        stockholm = { inherit accessKeyId region; };
      };

      vpc.example-vpc = {
        inherit accessKeyId region;
        name = "example";
        instanceTenancy = "default";
        enableDnsSupport = true;
        enableDnsHostnames = true;
        tags = {
          Source = "NixOps";
        };
        cidrBlock = "10.1.0.0/16";
      };

      vpcSubnets.example-subnet =
        { resources, ... }:

        {
          inherit accessKeyId region;
          vpcId = resources.vpc.example-vpc;
          cidrBlock = "10.1.0.0/24";
          zone = "eu-north-1a";
          mapPublicIpOnLaunch = true;
        };

      ec2SecurityGroups = {
        public-http-sg =
          { resources, ... }:

          {
            inherit accessKeyId region;
            vpcId = resources.vpc.example-vpc;
            rules = map (port: { fromPort = port; toPort = port; sourceIp = "0.0.0.0/0"; }) [
              80
              443
            ];
          };
        public-ssh-sg =
          { resources, ... }:

          {
            inherit accessKeyId region;
            vpcId = resources.vpc.example-vpc;
            rules = [{ fromPort = 22; toPort = 22; sourceIp = "0.0.0.0/0"; }];
          };
      };

      # Set up a custom route table to be able to associate the internet
      # gateway with the subnet and get internet access.
      vpcRouteTables.example-route-table =
        { resources, ... }:

        {
          inherit accessKeyId region;
          vpcId = resources.vpc.example-vpc;
        };

      # Associate the route table with the subnet.
      vpcRouteTableAssociations.example-route-table-assoc =
        { resources, ... }:

        {
          inherit accessKeyId region;
          subnetId = resources.vpcSubnets.example-subnet;
          routeTableId = resources.vpcRouteTables.example-route-table;
        };

      # Create an internet gateway.
      vpcInternetGateways.example-igw =
        { resources, ... }:

        {
          inherit accessKeyId region;
          vpcId = resources.vpc.example-vpc;
        };

      # Route all IPv4 traffic to the internet gateway. The route table
      # already has implicit local routes which take precedence over this.
      vpcRoutes.example-igw-route =
        { resources, ... }:

        {
          inherit accessKeyId region;
          routeTableId = resources.vpcRouteTables.example-route-table;
          destinationCidrBlock = "0.0.0.0/0";
          gatewayId = resources.vpcInternetGateways.example-igw;
        };

      # Allocate an elastic IP to use with the load balancer. This could
      # be moved to a new host if the need arises.
      elasticIPs = {
        load-balancer-ip = {
          inherit accessKeyId region;
          vpc = true;
        };
      };
    };

    load-balancer =
      { resources, lib, ... }:

      {
        deployment.targetEnv = "ec2";
        deployment.ec2 = {
          inherit accessKeyId region;
          ami = "ami-98a9ab98abobc";
          instanceType = "t3.small";
          ebsInitialRootDiskSize = 10;

          subnetId = resources.vpcSubnets.example-subnet;
          elasticIPv4 = resources.elasticIPs.load-balancer-ip;
          securityGroupIDs = with resources.ec2SecurityGroups; [
            public-http-sg.name
            public-ssh-sg.name
          ];
          associatePublicIpAddress = true;

          keyPair = resources.ec2KeyPairs.stockholm;
        };

        deployment.route53 = {
          inherit accessKeyId;
          hostName = "oslodemo.xlnaudio.com";
        };

        boot.loader.grub.device = lib.mkForce "/dev/nvme0n1";
      };

    webserver1 = php-host;
    webserver2 = php-host;
  };
  ```
* Create and deploy using
  ```
  $ nixops create -d aws-demo webserver_logical.nix webserver_physical_production.nix
  $ nixops deploy -d aws-demo
  ```

## Other interesting NixOps commands

* `nixops ssh -d <deployment> <host>`
  * Connect to a machine in a deployment over SSH.
  * Useful for troubleshooting, since we don't have to keep track of IP address 
    to host mapping.
* `nixops destroy -d <deployment>`
  * Take down everything in a deployment's physical specification.
* `nixops start -d <deployment>`
  * Start all machines in a deployment.
* `nixops stop -d <deployment>`
  * Stop all machines in a deployment.
* `nixops <command> -d <deployment> --include <host>
  * Only run the command on a single host within a deployment.
  * There is also `--exclude`.
