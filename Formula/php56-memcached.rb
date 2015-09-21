require File.expand_path("../../Abstract/abstract-php-extension", __FILE__)

class Php56Memcached < AbstractPhp56Extension
  init
  homepage "https://pecl.php.net/package/memcached"
  url "https://pecl.php.net/get/memcached-2.2.0.tgz"
  sha256 "17b9600f6d4c807f23a3f5c45fcd8775ca2e61d6eda70370af2bef4c6e159f58"
  head "https://github.com/php-memcached-dev/php-memcached.git"

  bottle do
    sha256 "5c63b711de449b4452466c47ac766e3381ad8783647d0afaa1e9bac6f4ad8feb" => :yosemite
    sha256 "9e788fe1e23ae0d22e1d833f53e922caad0ac018fc479fd9d4164a21b11417f4" => :mavericks
    sha256 "acc7d08a5f8411b7d180acab8ba986c0548ee288f60b84b342d588e905181369" => :mountain_lion
  end

  option "with-sasl", "Build with sasl support"

  depends_on "pkg-config" => :build
  depends_on "php56-igbinary"
  if build.with? "sasl"
    depends_on "libmemcached" => "with-sasl"
  else
    depends_on "libmemcached"
  end

  def install
    Dir.chdir "memcached-#{version}" unless build.head?

    ENV.universal_binary if build.universal?

    args = []
    args << "--with-libmemcached-dir=#{Formula["libmemcached"].opt_prefix}"
    args << "--enable-memcached-igbinary"
    args << "--enable-memcached-sasl" if build.with? "sasl"

    safe_phpize

    mkdir_p "ext/igbinary"
    cp "#{Formula["igbinary"].opt_include}/igbinary.h", "ext/igbinary/igbinary.h"

    system "./configure", "--prefix=#{prefix}",
                          phpconfig,
                          *args
    system "make"
    prefix.install "modules/memcached.so"
    write_config_file if build.with? "config-file"
  end

  def config_file
    # Use upsteam defaults (https://github.com/php-memcached-dev/php-memcached/blob/2.2.0/memcached.ini)
    # with default values pre-filled
    super + <<-EOS.undent

      ; Use session locking
      ; valid values: On, Off
      ; the default is On
      memcached.sess_locking = On

      ; Session spin lock retry wait time in microseconds.
      ; Be carefull when setting this value.
      ; Valid values are integers, where 0 is interpreted as
      ; the default value. Negative values result in a reduces
      ; locking to a try lock.
      ; the default is 150000
      memcached.sess_lock_wait = 150000

      ; The maximum time, in seconds, to wait for a session lock
      ; before timing out.
      ; Setting to 0 results in default behavior, which is to
      ; use max_execution_time.
      memcached.sess_lock_max_wait = 0;

      ; The time, in seconds, before a lock should release itself.
      ; Setting to 0 results in the default behaviour, which is to
      ; use the memcached.sess_lock_max_wait setting. If that is
      ; also 0, max_execution_time will be used.
      memcached.sess_lock_expire = 0;

      ; memcached session key prefix
      ; valid values are strings less than 219 bytes long
      ; the default value is "memc.sess.key."
      memcached.sess_prefix = "memc.sess.key."

      ; memcached session consistent hash mode
      ; if set to On, consistent hashing (libketama) is used
      ; for session handling.
      ; When consistent hashing is used, one can add or remove cache
      ; node(s) without messing up too much with existing keys
      ; default is Off
      memcached.sess_consistent_hash = Off

      ; Allow failed memcached server to automatically be removed
      memcached.sess_remove_failed = 1

      ; Write data to a number of additional memcached servers
      ; This is "poor man's HA" as libmemcached calls it.
      ; If this value is positive and sess_remove_failed is enabled
      ; when a memcached server fails the session will continue to be available
      ; from a replica. However, if the failed memcache server
      ; becomes available again it will read the session from there
      ; which could have old data or no data at all
      memcached.sess_number_of_replicas = 0

      ; memcached session binary mode
      ; libmemcached replicas only work if binary mode is enabled
      memcached.sess_binary = Off

      ; memcached session replica read randomize
      memcached.sess_randomize_replica_read = Off

      ; memcached connect timeout value
      ; In non-blocking mode this changes the value of the timeout
      ; during socket connection in milliseconds. Specifying -1 means an infinite timeout.
      memcached.sess_connect_timeout = 1000

      ; Session SASL username
      ; Both username and password need to be set for SASL to be enabled
      ; In addition to this memcached.use_sasl needs to be on
      memcached.sess_sasl_username = NULL

      ; Session SASL password
      memcached.sess_sasl_password = NULL

      ; Set the compression type
      ; valid values are: fastlz, zlib
      ; the default is fastlz
      memcached.compression_type = "fastlz"

      ; Compression factor
      ; Store compressed value only if the compression
      ; factor (saving) exceeds the set limit.
      ;
      ;  store compressed if:
      ;    plain_len > comp_len * factor
      ;
      ; the default value is 1.3 (23% space saving)
      memcached.compression_factor = "1.3"

      ; The compression threshold
      ;
      ; Do not compress serialized values below this threshold.
      ; the default is 2000 bytes
      memcached.compression_threshold = 2000

      ; Set the default serializer for new memcached objects.
      ; valid values are: php, igbinary, json, json_array, msgpack
      ;
      ; json - standard php JSON encoding. This serializer
      ;        is fast and compact but only works on UTF-8
      ;        encoded data and does not fully implement
      ;        serializing. See the JSON extension.
      ; json_array - as json, but decodes into arrays
      ; php - the standard php serializer
      ; igbinary - a binary serializer
      ; msgpack - a cross-language binary serializer
      ;
      ; The default is igbinary if available, then msgpack if available, then php otherwise.
      memcached.serializer = "igbinary"

      ; Use SASL authentication for connections
      ; valid values: On, Off
      ; the default is Off
      memcached.use_sasl = Off

      ; The amount of retries for failed store commands.
      ; This mechanism allows transparent fail-over to secondary servers when
      ; set/increment/decrement/setMulti operations fail on the desired server in a multi-server
      ; environment.
      ; the default is 2
      memcached.store_retry_count = 2
    EOS
  end

  test do
    shell_output("php -m").include?("memcached")
  end
end
