require 'spec_helper'
require 'open3'

describe 'be_gateway' do
  it 'loads without requiring anything else first' do
    _out, err, status = Open3.capture3(RbConfig.ruby, '-Ilib', '-e', "require 'be_gateway'; BeGateway::Client")

    expect(status).to be_success, err
  end
end
