require 'should_not/rspec'
require 'docker'

Docker.options[:read_timeout] = 50 * 60 # 50 mins

# Print docker chunk logs.
class DockerLogger
  def intialize
    @status = nil
  end

  def parse_chunk(chunk)
    return chunk if chunk.is_a?(Hash)
    JSON.parse(chunk)
  rescue JSON::ParserError
    { 'stream' => chunk }
  end

  def print_status(status)
    if status != @status
      puts
      @status = status
      print "#{status}." unless status.nil?
    elsif !status.nil?
      print '.'
    end
    STDOUT.flush
  end

  def print_chunk(chunk)
    chunk_json = parse_chunk(chunk)
    print_status(chunk_json['status'])
    return unless chunk_json.key?('stream')
    puts chunk_json['stream']
  end
end

# Module responsible for the creation and destruction of the docker image.
module DockerContext
  extend RSpec::SharedContext

  # DockerContext constructor.
  def initialize(*args)
    super
    ObjectSpace.define_finalizer(self, proc { cleanup_image })
  end

  def dockerfile_location
    ENV['DOCKERFILE_LOCATION']
  end

  # Dockerfile directory path.
  def dockerfile_dir
    root = File.join(File.dirname(__FILE__), '..')
    dockerfile_location.nil? ? root : File.join(root, dockerfile_location)
  end

  def travis_ci?
    ENV['TRAVIS_CI'] == 'true'
  end

  # Returns the Docker::Image instance built from the Dockerfile.
  def image
    logger = DockerLogger.new
    @image ||= Docker::Image.build_from_dir(dockerfile_dir) do |chunk|
      logger.print_chunk(chunk)
    end
  end

  # Removes the temporary docker image used to run the tests.
  def cleanup_image
    return if @image.nil? || travis_ci?
    @image.remove(force: true)
    @image = nil
  end

  # Helper to get the docker image configuration hash easily.
  let(:image_config) { image.json['Config'] }
end

RSpec.configure do |config|
  # Prohibit using the should syntax
  config.expect_with :rspec do |spec|
    spec.syntax = :expect
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  # --seed 1234
  config.order = 'random'

  config.color = true
  config.formatter = :documentation
  config.tty = true

  config.include DockerContext
end
