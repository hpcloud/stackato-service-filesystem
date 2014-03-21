## This is an example implementation of the filesystem service backend
## used by Stackato (through the 'fence' daemon).

require 'kato/config'

class Fence
  class Stackato
    class FilesystemService
      def self.create(opts={})
        config = Kato::Config.get('filesystem_node')
        base_dir  = config["base_dir"]
        limit     = opts[:limit] || 100 # MB

        instanceid = Fence::Util.uuid[1..15]

        Fence.logger.info "provisioning filesystem service #{instanceid}"

        f = Fiber.current

        service_creation = lambda do
          unless File.directory? base_dir
            FileUtils.mkdir_p base_dir
            FileUtils.chown_R 'stackato', 'stackato', base_dir
            FileUtils.chmod 0755, ['/var/vcap', '/var/vcap/services']
          end

          user = "stackatofs-#{instanceid}"
          home = File.join base_dir, user
          dir = File.join home, "storage"

          ssh = File.join home, ".ssh"
          privkey_loc = File.join ssh, "stackato_fs"

          quota = limit.to_i * 1024 # limit is in MB, quota is in KB

          begin
            system("/usr/sbin/useradd --system -K SYS_UID_MIN=1500 -K SYS_UID_MAX=10000 -m -b #{base_dir} -s /bin/bash #{user} 2>&1 >/dev/null")
            system("/usr/bin/passwd -l #{user} 2>&1 >/dev/null") # disable passworded login

            system("/usr/sbin/setquota -u #{user} 0 #{quota} 0 0 -a")

            FileUtils.mkdir_p ssh
            system("/usr/bin/ssh-keygen -t rsa -N '' -f #{privkey_loc} 2>&1 >/dev/null")

            private_key = IO.read privkey_loc
            FileUtils.cp File.join(ssh, "stackato_fs.pub"), File.join(ssh, "authorized_keys")

            FileUtils.mkdir_p dir

            FileUtils.chown_R user, user, home
            FileUtils.chmod_R 0600, ssh
            FileUtils.chmod 0755, [ ssh, home ]
            FileUtils.chmod 0644, File.join(ssh, "authorized_keys")

            FileUtils.chmod_R 0700, dir

            instance = {
              :instance_id => instanceid,
              :private_key => private_key,
              :dir   => dir,
              :user  => user,
            }

            return instance
          rescue
            destroy(instanceid)
          end
        end

        cb = Proc.new do |instance|
          f.resume(instance)
        end

        EM.defer(service_creation, cb)

        instance = Fiber.yield

        Fence.logger.info "filesystem service #{instanceid} provisioned"

        return instance
      end

      def self.destroy(id)
        config = Kato::Config.get('filesystem_node')
        base_dir  = config["base_dir"]

        Fence.logger.debug "destroying filesystem service #{id}"

        cleanup = lambda do
          user = "stackatofs-#{id}"
          dir = File.join base_dir, user
          system("/usr/sbin/userdel -r #{user}")
          FileUtils.rm_rf(dir)

          return true
        end

        f  = Fiber.current
        cb = Proc.new { |res| f.resume(res) }
        EM.defer(cleanup, cb)

        return Fiber.yield
      end

      def self.pull_private_key(id)
        config = Kato::Config.get('filesystem_node')
        base_dir  = config["base_dir"]

        private_key = File.join base_dir, "stackatofs-#{id}", ".ssh", "stackato_fs"
        return File.file?(private_key) ? IO.read(private_key) : ''
      end

      def self.prepare_volume(name, creds)
        volume_uuid = Fence::Util.uuid

        localpath = ::File.join( Fence.config[:sshfs_dir], volume_uuid )

        Fence.logger.debug "preparing volume for #{name}, being mounted into #{localpath} from #{creds[:host]}"

        private_key_dir = Fence.config[:private_key_dir]
        FileUtils.mkdir_p(private_key_dir) unless File.directory? private_key_dir

        privkey = creds[:private_key]
        privkeyfilename = "stackatofs-" + volume_uuid
        privkeypath = File.join private_key_dir, privkeyfilename
        File.open(privkeypath, 'w') { |f| f.write(privkey) }
        FileUtils.chmod 0600, privkeypath

        user = creds[:user]
        path = creds[:dir]
        host = creds[:host]

        FileUtils.mkdir_p(localpath)

        f = Fiber.current
        EM.system("sshfs -o IdentityFile=#{privkeypath} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o cache=no -o idmap=user -o allow_other -o reconnect #{user}@#{host}:#{path} #{localpath}") do |output, status|
          f.resume(output, status)
        end

        output, status = Fiber.yield

        unless status
          raise "unable to mount sshfs volume #{name}, creds #{creds.inspect}, output: #{output}"
        end

        return localpath
      end

      def self.destroy_volume(fs)
        path = fs["host_path"]

        Fence.logger.debug "tearing down fs volume #{path}"

        private_key_dir = Fence.config[:private_key_dir]

        cleanup = lambda do
          system("fusermount -uq #{path}")
          system("fusermount -quz #{path}")

          FileUtils.rm_rf(path)

          name = File.basename(path)
          privkeyfilename = "stackatofs-" + name
          privkeypath = File.join private_key_dir, privkeyfilename
          if File.exists? privkeypath
            FileUtils.rm(privkeypath)
          end

          return true
        end

        f  = Fiber.current
        cb = Proc.new { |res| f.resume(res) }
        EM.defer(cleanup, cb)

        return Fiber.yield
      end
    end
  end
end
