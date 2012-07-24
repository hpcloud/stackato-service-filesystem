# Copyright (c) 2009-2011 VMware, Inc.

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', '..', 'base', 'lib')
require 'base/provisioner'
require 'filesystem_service/common'

class VCAP::Services::Filesystem::Provisioner < VCAP::Services::Base::Provisioner
  include VCAP::Services::Filesystem::Common
end
