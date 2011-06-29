#
# Author:: Ezra Pagel (<ezra@cpan.org>)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/knife'
require 'chef/knife/VsphereBaseCommand'
require 'rbvmomi'

class Chef
  class Knife
    class VsphereVmClone < VsphereBaseCommand

      banner "knife vsphere vm clone (options)"

      get_common_options

      option :template,
      :short => "-t TEMPLATE",
      :long => "--template TEMPLATE",
      :description => "The template to create the VM from"
      
      option :vmname,
      :short => "-N VMNAME",
      :long => "--vmname VMNAME",
      :description => "The name for the new virtual machine"

      def run

        $stdout.sync = true
        
        vim = get_vim_connection

        dcname = config[:vsphere_dc] || Chef::Config[:knife][:vsphere_dc]
        dc = vim.serviceInstance.find_datacenter(dcname) or abort "datacenter not found"
        vmFolder = dc.vmFolder
        hosts = dc.hostFolder.children
        rp = hosts.first.resourcePool

        template = config[:template] or abort "source template name required"
        vmname = config[:vmname] or abort "destination vm name required"

        puts "searching for template #{template}"

        src_vm = dc.find_vm(template) or abort "VM not found"

        rspec = RbVmomi::VIM.VirtualMachineRelocateSpec(:pool => rp)
        spec = RbVmomi::VIM.VirtualMachineCloneSpec(:location => rspec,
                                                    :powerOn => false,
                                                    :template => false)

        task = src_vm.CloneVM_Task(:folder => src_vm.parent, :name => vmname, :spec => spec)
        puts "Cloning template #{template} to new VM #{vmname}"
        task.wait_for_completion        
        puts "Finished creating virtual machine #{vmname}"

      end
    end
  end
end
