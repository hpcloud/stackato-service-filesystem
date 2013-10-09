# Copyright (c) 2009-2011 VMware, Inc.
$:.unshift File.join(File.dirname(__FILE__), ".")
$:.unshift File.join( ENV['HOME'], 'stackato', 'vcap', 'fence', 'fence-client', 'lib' )

require "base/node"
require "uuidtools"
require "fence/client"

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
    @max_fs_size = options[:max_fs_size]
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

  def pre_send_announcement
    @capacity_lock.synchronize do
      Dir.entries(@base_dir).each do |entry|
        next if entry == '.'
        next if entry == '..'

        if ::File.directory? ::File.join(@base_dir, entry)
          @capacity -= capacity_unit
        end
      end
    end
  end

  def announcement
    @capacity_lock.synchronize do
      {
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

  def provision(plan, credentials=nil, version=nil, db_file = nil)
    instance = ProvisionedService.new
    fence = Fence::Client.new
    if credentials
      instance.name        = credentials["name"]
      instance.user        = credentials["user"]
      instance.dir         = credentials["dir"]
      instance.private_key = credentials["private_key"]
    else
      begin
        fs_instance = fence.create_filesystem_instance( :limit => @max_fs_size )
        # instance = {
        #   "instance_id" => 'u3h5ui245i24g5oi24g5',
        #   "dir"         => '/var/vcap/services/filesystem/storage/filesystem-u3h5...',
        #   "private_key" => '-----BEGIN RSA PRIVATE KEY...',
        # }
        raise FilesystemError.new(FilesystemError::FILESYSTEM_CREATE_INSTANCE_DIR_FAILED, name) if fs_instance == nil

        instance.name        = fs_instance["instance_id"]
        instance.private_key = fs_instance["private_key"]
        instance.user        = fs_instance["user"]
        instance.dir         = fs_instance["dir"]
      rescue => e
        fence.cleanup_filesystem_instance( :service_id => instance.name )
        raise e
      end
    end

    gen_credentials(instance)
  end

  def unprovision(instance_id, credentials_list = [])
    @logger.info("unprovisioning instance: #{instance_id}")
    Fence::Client.new.cleanup_filesystem_instance( :service_id => instance_id )
    {}
  end

  def get_instance(name)
    svc = ProvisionedService.new
    svc.name = name
    svc.user = "stackatofs-#{name}"
    svc.dir  = File.join(@base_dir, svc.user, "storage")

    raise FilesystemError.new(FilesystemError::FILESYSTEM_FIND_INSTANCE_FAILED, name) unless File.directory? svc.dir

    private_key = Fence::Client.new.pull_private_key( :service_id => svc.name )
    raise FilesystemError.new(FilesystemError::FILESYSTEM_FIND_INSTANCE_FAILED, name) if private_key == ""
    svc.private_key = private_key

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
