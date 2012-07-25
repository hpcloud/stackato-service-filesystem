# Copyright (c) 2009-2011 VMware, Inc.
$:.unshift File.join(File.dirname(__FILE__), ".")

require "base/node"
require "uuidtools"
require "vcap/sysadm"

module VCAP
  module Services
    module Filesystem
      class Node < VCAP::Services::Base::Node
      end
    end
  end
end

require "filesystem_service/common"
require "filesystem_service/error"

class VCAP::Services::Filesystem::Node

  include VCAP::Services::Filesystem::Common
  include VCAP::Services::Filesystem

  def initialize(options)
    super(options)

    @available_capacity = options[:capacity]
    @base_dir = options[:base_dir]
    FileUtils.mkdir_p(@base_dir)
  end

  class ProvisionedService
    attr_accessor :name, :user, :private_key, :plan, :dir

    def initialize
      @name        = nil
      @user        = nil
      @private_key = nil
      @dir         = nil
      @plan        = nil
    end
  end

  def announcement
    @capacity_lock.synchronize do
      a = {
          :available_capacity => @capacity,
          :capacity_unit => capacity_unit
      }
    end
  end

  def gen_credentials(instance)
    credentials = {
      "hostname"    => @local_ip,
      "host"        => @local_ip,
      "dir"         => instance.dir,
      "user"        => instance.user,
      "private_key" => instance.private_key,
      "name"        => instance.name,
    }
  end

  def provision(plan, credentials=nil, db_file = nil)
    instance = ProvisionedService.new
    if credentials
      instance.name        = credentials["name"]
      instance.user        = credentials["user"]
      instance.dir         = credentials["dir"]
      instance.private_key = credentials["private_key"]
    else
      begin
        per_fs = @vcap_config[:max_fs_size] # in MB

        if (@vcap_config[:capacity] - @capacity) < 1
          unless @vcap_config[:allow_over_provisioning]
            @logger.warn("Insufficient space, requesting #{per_fs}MB, have #{@capacity} provisioned services")
            raise FilesystemError.new(FilesystemError::FILESYSTEM_INSUFFICIENT_SPACE)
          end
        end
      
        limit = per_fs

        fs_instance = SA::create_filesystem_instance(limit)
        # instance = {
        #   "instance_id" => 'u3h5ui245i24g5oi24g5',
        #   "dir"         => '/var/vcap/services/filesystem/storage/filesystem-u3h5...',
        #   "private_key" => '-----BEGIN RSA PRIVATE KEY...',
        # }
        raise FilesystemError.new(FilesystemError::FILESYSTEM_CREATE_INSTANCE_DIR_FAILED, name) if instance == nil

        instance.name        = fs_instance["instance_id"]
        instance.private_key = fs_instance["private_key"]
        instance.user        = fs_instance["user"]
        instance.dir         = fs_instance["dir"]
      rescue => e
        SA::cleanup_filesystem_instance(instance.id)
        raise e
      end
    end

    gen_credentials(instance)
  end

  def unprovision(instance_id, credentials_list = [])
    @logger.info("unprovisioning instance: #{instance_id}")
    SA::cleanup_filesystem_instance(instance_id)
    {}
  end

  def get_instance(name)
    svc = ProvisionedService.new
    svc.name = name
    svc.user = name
    svc.dir  = File.join(@base_dir, name)

    raise FilesystemError.new(FilesystemError::FILESYSTEM_FIND_INSTANCE_FAILED, name) unless File.directory? svc.dir

    private_key_storage = File.join(svc.dir, ".ssh", "id_rsa")
    raise FilesystemError.new(FilesystemError::FILESYSTEM_FIND_INSTANCE_FAILED, name) unless File.file? private_key_storage

    svc.private_key = IO.read(private_key_storage)

    svc
  end

  def bind(instance_id, binding_options = :all, credentials = nil)
    instance = nil
    if credentials
      instance = get_instance(credentials["name"])
    else
      instance = get_instance(instance_id)
    end
    gen_credentials(instance)
  end

  def unbind(credentials)
    {}
  end
end
