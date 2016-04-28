#! /usr/bin/env ruby
#
# Write a servers.json file to be consumed by Luna Rossa. This 
# file describes the Xen servers available for testing. 
#
# This code relies on the Vagrant environment and must
# be run after "vagrant up"
#
# This code probably should go into the Vagrant code

require 'json'

# gather IP address for each host
$ip = Hash.new
["host1", "host2", "host3"].each do |h|
  IO.popen("vagrant ssh #{h} -c /scripts/get_public_ip.sh") do |io|
    io.each_line do |line|
        parts  = line.chop.split(",")
        $ip[h] = parts[1]
    end
  end
end

# infrastructure
# why is this host using a different format?
["infrastructure"].each do |h|
  IO.popen("vagrant ssh #{h} -c /scripts/get_ip.sh") do |io|
    io.each_line do |line|
        $ip[h] = line.chop
    end
  end
end


# build one hash per server, holding information about it
servers = []
$ip.each_pair do |host, ip| 
  servers << { 
      :name => host, 
      :ssh => ["vagrant","ssh", host , "-c"],
      :xen => {
          :api => "http://#{ip}",
          :user => "root",
          :password => "xenroot"
      }
    }
end

$servers =
  { :version => "0.1",
    :servers => servers
  }

puts $servers.to_json
exit 0

