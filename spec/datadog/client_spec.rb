describe Datadog::Client do
  before do
    Datadog.reset!
  end

  after do
    Datadog.reset!
  end

  describe 'module configuration' do
    before do
      Datadog.reset!
      Datadog.configure do |config|
        Datadog::Configurable.keys.each do |key|
          config.send("#{key}=", "Some #{key}")
        end
      end
    end

    after do
      Datadog.reset!
    end

    it 'inherits the module configuration' do
      client = Datadog::Client.new
      Datadog::Configurable.keys.each do |key|
        expect(client.instance_variable_get(:"@#{key}")).to eq("Some #{key}")
      end
    end

    describe 'with class level configuration' do
      before do
        @opts = {
          connection_options: { ssl: { verify: false } },
          api_key: test_datadog_api_key,
          application_key: test_datadog_app_key
        }
      end

      it 'overrides module configuration' do
        client = Datadog::Client.new(@opts)
        expect(client.instance_variable_get(:"@api_key")).to eq(test_datadog_api_key)
        expect(client.api_endpoint).to eq(Datadog.api_endpoint)
      end

      it 'can set configuration after initialization' do
        client = Datadog::Client.new
        client.configure do |config|
          @opts.each do |key, value|
            config.send("#{key}=", value)
          end
        end
        expect(client.instance_variable_get(:"@api_key")).to eq(test_datadog_api_key)
        expect(client.api_endpoint).to eq(Datadog.api_endpoint)
      end

      it 'masks api keys on inspect' do
        client = Datadog::Client.new(api_key: test_datadog_api_key)
        inspected = client.inspect
        expect(inspected).not_to include(test_datadog_api_key)
      end

      it 'masks application keys on inspect' do
        client = Datadog::Client.new(application_key: test_datadog_app_key)
        inspected = client.inspect
        expect(inspected).not_to include(test_datadog_app_key)
      end
    end
  end

  describe 'content type' do
    it 'sets a default Content-Type header' do
      query_params_request = stub_get('').with(headers: { 'Content-Type' => 'application/json' })
      Datadog.get '', {}
      expect(query_params_request).to have_been_requested
    end
  end

  describe '.agent' do
    before do
      Datadog.reset!
    end
    it 'acts like a Sawyer agent' do
      expect(Datadog.client.agent).to respond_to :start
    end
    it 'caches the agent' do
      agent = Datadog.client.agent
      expect(agent.object_id).to eq(Datadog.client.agent.object_id)
    end
  end # .agent

  describe '.validate' do
    it 'validates API key' do
      VCR.use_cassette 'validate' do
        client = Datadog.client
        client.api_key = test_datadog_api_key
        valid = client.validate
        expect(valid.valid).to be_truthy
      end
    end

    it 'passes creds in the query string' do
      validate_request = stub_get('validate')
      client = Datadog.client
      client.api_key = test_datadog_api_key
      client.application_key = test_datadog_app_key
      client.validate
      assert_requested validate_request
    end
  end

  describe '.last_response', :vcr do
    it 'caches the last agent response' do
      Datadog.reset!
      client = Datadog.client
      expect(client.last_response).to be_nil
      client.validate
      expect(client.last_response.status).to eq(200)
    end
  end # .last_response

  describe '.get', :vcr do
    before(:each) do
      Datadog.reset!
    end
    it 'handles query params' do
      query_params_request = stub_get('')
                             .with(query: { foo: 'bar' })

      Datadog.get '', foo: 'bar'
      expect(query_params_request).to have_been_requested
    end
    it 'handles headers' do
      query_headers_request = stub_get('zen')
                              .with(query: { foo: 'bar' }, headers: { accept: 'text/plain' })

      Datadog.get 'zen', foo: 'bar', accept: 'text/plain'
      expect(query_headers_request).to have_been_requested
    end
  end # .get

  describe 'when making requests' do
    before do
      Datadog.reset!
      @client = Datadog.client
    end

    it 'Accepts application/json by default' do
      VCR.use_cassette 'validate' do
        validate_request = stub_get('validate').with(headers: { accept: 'application/json' })
        @client.validate
        expect(validate_request).to have_been_requested
        expect(@client.last_response.status).to eq(200)
      end
    end

    it 'sets a default user agent' do
      validate_request = stub_get('validate').with(headers: { user_agent: Datadog::Default.user_agent })
      @client.validate
      expect(validate_request).to have_been_requested
      expect(@client.last_response.status).to eq(200)
    end

    it 'sets a custom user agent' do
      user_agent = 'Mozilla/5.0 I am Spartacus!'

      validate_request = stub_get('validate').with(headers: { user_agent: user_agent })
      client = Datadog::Client.new(user_agent: user_agent)
      client.validate
      expect(validate_request).to have_been_requested
      expect(client.last_response.status).to eq(200)
    end

    xit 'sets a proxy server' do
      Datadog.configure do |config|
        config.proxy = 'http://proxy.example.com:80'
      end
      conn = Datadog.client.send(:agent).instance_variable_get(:"@conn")
      expect(conn.proxy[:uri].to_s).to eq('http://proxy.example.com')
    end

    it 'passes along request headers for POST' do
      headers = { 'X-Datadog-Foo' => 'bar' }
      series_request = stub_post('series')
                       .with(headers: headers)
                       .to_return(status: 202)
      client = Datadog::Client.new
      client.post 'series', headers: headers
      expect(series_request).to have_been_requested
      expect(client.last_response.status).to eq(202)
    end
  end

  context 'error handling' do
    before do
      Datadog.reset!
      VCR.turn_off!
    end

    after do
      VCR.turn_on!
    end

    it 'raises on 403' do
      stub_get('validate').to_return(status: 403)
      expect { Datadog.get('validate') }.to raise_error Datadog::Forbidden
    end

    it 'raises on 404' do
      stub_get('booya').to_return(status: 404)
      expect { Datadog.get('booya') }.to raise_error Datadog::NotFound
    end

    it 'raises on 500' do
      stub_get('boom').to_return(status: 500)
      expect { Datadog.get('boom') }.to raise_error Datadog::InternalServerError
    end

    xit 'includes a message' do
      stub_get('boom')
        .to_return \
          status: 422,
          headers: {
            content_type: 'application/json'
          },
          body: { message: 'No repository found for hubtopic' }.to_json
      begin
        Datadog.get('boom')
      rescue Datadog::UnprocessableEntity => e
        expect(e.message).to include('GET https://api.github.com/boom: 422 - No repository found')
      end
    end

    xit 'includes an error' do
      stub_get('/boom')
        .to_return \
          status: 422,
          headers: {
            content_type: 'application/json'
          },
          body: { error: 'No repository found for hubtopic' }.to_json
      begin
        Datadog.get('/boom')
      rescue Datadog::UnprocessableEntity => e
        expect(e.message).to include('GET https://api.github.com/boom: 422 - Error: No repository found')
      end
    end

    xit 'includes an error summary' do
      stub_get('/boom')
        .to_return \
          status: 422,
          headers: {
            content_type: 'application/json'
          },
          body: {
            message: 'Validation Failed',
            errors: [
              resource: 'Issue',
              field: 'title',
              code: 'missing_field'
            ]
          }.to_json
      begin
        Datadog.get('/boom')
      rescue Datadog::UnprocessableEntity => e
        expect(e.message).to include('GET https://api.github.com/boom: 422 - Validation Failed')
        expect(e.message).to include('  resource: Issue')
        expect(e.message).to include('  field: title')
        expect(e.message).to include('  code: missing_field')
      end
    end

    xit 'exposes errors array' do
      stub_get('/boom')
        .to_return \
          status: 422,
          headers: {
            content_type: 'application/json'
          },
          body: {
            message: 'Validation Failed',
            errors: [
              resource: 'Issue',
              field: 'title',
              code: 'missing_field'
            ]
          }.to_json
      begin
        Datadog.get('/boom')
      rescue Datadog::UnprocessableEntity => e
        expect(e.errors.first[:resource]).to eq('Issue')
        expect(e.errors.first[:field]).to eq('title')
        expect(e.errors.first[:code]).to eq('missing_field')
      end
    end

    xit 'handles an error response with an array body' do
      stub_get('/user').to_return \
        status: 500,
        headers: {
          content_type: 'application/json'
        },
        body: [].to_json
      expect { Datadog.get('/user') }.to raise_error Datadog::ServerError
    end
  end

  describe '.as_app', pending: 'unimplemented' do
    before do
      @client_id = '97b4937b385eb63d1f46'
      @client_secret = 'd255197b4937b385eb63d1f4677e3ffee61fbaea'

      Datadog.reset!
      Datadog.configure do |config|
        config.access_token  = 'a' * 40
        config.client_id     = @client_id
        config.client_secret = @client_secret
        config.per_page      = 50
      end

      @root_request = stub_get basic_github_url '/',
                                                login: @client_id, password: @client_secret
    end

    it 'uses preconfigured client and secret' do
      client = Datadog.client
      login = client.as_app(&:login)
      expect(login).to eq(@client_id)
    end

    it 'requires a client and secret' do
      Datadog.reset!
      client = Datadog.client
      expect do
        client.as_app(&:get)
      end.to raise_error Datadog::ApplicationCredentialsRequired
    end

    it 'duplicates the client' do
      client = Datadog.client
      page_size = client.as_app(&:per_page)
      expect(page_size).to eq(client.per_page)
    end

    it 'uses client and secret as Basic auth' do
      client = Datadog.client
      app_client = client.as_app do |c|
        c
      end
      expect(app_client).to be_basic_authenticated
    end

    it 'makes authenticated requests' do
      stub_get github_url('/user')

      client = Datadog.client
      client.get '/user'
      client.as_app do |c|
        c.get '/'
      end

      assert_requested @root_request
    end
  end
end
