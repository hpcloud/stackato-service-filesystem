# Copyright (c) 2009-2011 VMware, Inc.

module VCAP
  module Services
    module Filesystem
      class FilesystemError < VCAP::Services::Base::Error::ServiceError
        # 31900 - 31999  Filesystem-specific Error
        FILESYSTEM_CREATE_INSTANCE_DIR_FAILED             = [31900, HTTP_INTERNAL, "Could not create instance directory: %s"]
        FILESYSTEM_FIND_INSTANCE_FAILED                   = [31904, HTTP_NOT_FOUND, "Could not find instance: %s"]
      end
    end
  end
end
