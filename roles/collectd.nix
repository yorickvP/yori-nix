{ config, pkgs, lib, ...}:
let
  secrets = import <secrets>;
in
{
  services.collectd = {
    enable = true;
    extraConfig = ''
      LoadPlugin network

      LoadPlugin conntrack
      LoadPlugin cpu
      LoadPlugin df
      LoadPlugin disk
      LoadPlugin interface
      LoadPlugin fhcount
      LoadPlugin load
      LoadPlugin memory
      LoadPlugin processes
      LoadPlugin swap
      LoadPlugin tcpconns
      LoadPlugin uptime
      LoadPlugin users
      LoadPlugin sensors
       
       
      <Plugin tcpconns>
       LocalPort "443"
      </Plugin>
      <Plugin "network">
        <Server "graphs.yori.cc">
          Username "${config.networking.hostName}"
          Password "${secrets.influx_pass.${config.networking.hostName}}"
        </Server>
      </Plugin>
      <Plugin "df">
        FSType "btrfs"
        FSType "ext3"
        FSType "ext4"
        FSType "vfat"
      </Plugin>
    '';
  };
  boot.kernel.sysctl."net.core.rmem_max" = 26214400;
  boot.kernel.sysctl."net.core.rmem_default" = 26214400;
  nixpkgs.config.packageOverrides = pkgs: { 
    collectd = pkgs.collectd.override {
      jdk = null;
      libcredis = null;
      libdbi = null;
      libmemcached = null;  cyrus_sasl = null;
      libmodbus = null;
      libnotify = null; gdk_pixbuf = null;
      libsigrok = null;
      libvirt = null;
      libxml2 = null;
      libtool = null;
      lvm2 = null;
      mysql = null;
      protobufc = null;
      python = null;
      rabbitmq-c = null;
      riemann_c_client = null;
      rrdtool = null;
      varnish = null;
      yajl = null;
      net_snmp = null;
    };
  };
}
