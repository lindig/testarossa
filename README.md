# Testarossa

Testarossa is a small system-level test framework using Xen-on-Xen with the
Xenserver provider for Vagrant. It uses Vagrant to provide a test
environment and Luna Rossa to execute tests.

## Dependencies

Get vagrant from https://www.vagrantup.com/downloads.html

```sh
# Vagrant
$ vagrant plugin install vagrant-xenserver

# OCaml
$ opam remote add xapi-project git://github.com/xapi-project/opam-repo-dev
$ opam pin add luna-rossa https://github.com/xapi-project/luna-rossa.git 
$ DEPS='luna-rossa'
$ opam depext $DEPS
$ opam install $DEPS
```

You'll also want to create a stanza in your `~/.vagrant.d/Vagrantfile`
for the XenServer provider configuration:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :xenserver do |xs|
    xs.xs_host = "<host>
    xs.xs_username = "root"
    xs.xs_password = "<password>"
  end
end
```

## Usage

1.  Inspect the file `etc/tests.json`. It describes the test configurations
    for Luna Rossa. 

```sh
$ ./testarossa --help
$ ./testarossa
```




