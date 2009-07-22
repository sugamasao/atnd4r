require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'atnd4r'

Spec::Runner.configure do |config|
  
end

# HTTP MOCK
def create_http_mock(body = "", code = "", status = "")
  @response_mock = mock(Net::HTTPResponse)
  @response_mock.stub!(:body).and_return(body)
  @response_mock.stub!(:code).and_return(code)
  @response_mock.stub!(:[]).and_return(status)
  @http_mock = mock('http')
  @http_mock.stub!(:get).and_return(@response_mock)

  return @http_mock
end

