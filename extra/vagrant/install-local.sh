#!/bin/bash
rm -rf /home/vagrant/.gvm
cp -r /vagrant /home/vagrant/.gvm
echo "export GVM_ROOT=/vagrant
builtin . \$GVM_ROOT/scripts/gvm-default" > /home/vagrant/.gvm/scripts/gvm
echo ". /home/vagrant/.gvm/scripts/gvm"
