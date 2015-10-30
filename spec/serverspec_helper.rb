require_relative 'spec_helper'
require 'serverspec'

set :os, family: :alpine
set :backend, :docker

# Module to setup the Serverspec docker context.
module DockerServerspecContext
  extend RSpec::SharedContext

  before(:all) { set :docker_image, image.id }
end

RSpec.configure { |c| c.include DockerServerspecContext }
