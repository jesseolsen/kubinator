#MIT License
#Copyright (c) 2017 phR0ze
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

nodes = [
  <%= nodes %>
]

Vagrant.configure("2") do |config|
  <% if boxver %>config.vm.box_version = "<%= boxver %>"<% end %>
  config.vm.box = "phR0ze/cyberlinux-k8snode"
  config.vm.synced_folder(".", "/vagrant", disabled:true)

  # Configure each node
  #-----------------------------------------------------------------------------
  nodes.each do |node|
    config.vm.define node[:host] do |conf|
      conf.vm.hostname = node[:host]

      # Custom VirtualBox settings
      #-------------------------------------------------------------------------
      conf.vm.provider :virtualbox do |vbox|
        vbox.name = node[:host]
        vbox.cpus = node[:cpus]
        vbox.memory = node[:ram]
        vbox.customize(["modifyvm", :id, "--vram", node[:vram]])
        vbox.customize(["modifyvm", :id, "--accelerate3d", node[:v3d]])

        # Configure Audio
        vbox.customize(["modifyvm", :id, "--audio", 'alsa', "--audiocontroller", "ac97"])

        # Configure Networking
        vbox.customize(["modifyvm", :id, "--nic1", "nat"])
        vbox.customize(["modifyvm", :id, "--nic2", "hostonly"])
        vbox.customize(["modifyvm", :id, "--hostonlyadapter2", node[:net]])
      end

      # Custom VM provisioning
      #-------------------------------------------------------------------------
      conf.vm.provision :shell do |script|

        # Add deployed nodes to the no_proxy
        no_proxy = nil
        if node[:proxy]
          no_proxy = node[:no_proxy] || "localhost,127.0.0.1"
          _nodes = nodes.map{|x| x[:ip][0..x[:ip].index('/')-1]}.select{|x| !no_proxy.include?(x)}
          no_proxy += ",#{nodes * ','}" if _nodes.any?
        end

        # Set the bash script to execute for configuration
        script.args = [node[:ip], node[:proxy].to_s, no_proxy.to_s, node[:ipv6].to_s]
        script.inline = <<-SHELL
          echo "Configuring host-only static ip address"
          echo "VM Static IP: ${1}"
          echo -e "[Match]\\nName=enp0s8 eth0\\n" > /etc/systemd/network/10-static.network
          echo -e "[Network]\\nAddress=${1}\\nIPForward=kernel" >> /etc/systemd/network/10-static.network

          if [ x"${2}" != x"" ]; then
            echo "Configuring proxy settings"
            sed -i -e "s|^\\(proxy\\)=.*|\\1=${2}|" /usr/bin/setproxy
            [ x"${3}" != x"" ] && sed -i -e "s|^\\(no_proxy\\)=.*|\\1=${3}|" /usr/bin/setproxy
            /usr/bin/setproxy
          else
            echo "No proxy settings required"
          fi

          if [ x"${4}" != x"" ]; then
            echo "Enabling IPv6"
            [ x"${4}" != x"" ] && sed -i -e "s/ ipv6.disable=1//" /boot/syslinux/syslinux.cfg
          else
            echo "Leaving IPv6 disabled"
          fi

          echo "Done configuring vagrant box"
          SHELL
      end

    end
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
