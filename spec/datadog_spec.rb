describe Datadog do
  before do
    Datadog.reset!
  end

  after do
    Datadog.reset!
  end

  it 'sets defaults' do
    Datadog::Configurable.keys.each do |key|
      expect(Datadog.instance_variable_get(:"@#{key}")).to eq(Datadog::Default.send(key))
    end
  end

  describe '.client' do
    it 'creates an Datadog::Client' do
      expect(Datadog.client).to be_kind_of Datadog::Client
    end
    it 'caches the client when the same options are passed' do
      expect(Datadog.client).to eq(Datadog.client)
    end
    it 'returns a fresh client when options are not the same' do
      client = Datadog.client
      Datadog.api_key = '87614b09dd141c22800f96f11737ade5226d7ba8'
      client_two = Datadog.client
      client_three = Datadog.client
      expect(client).not_to eq(client_two)
      expect(client_three).to eq(client_two)
    end
  end

  describe '.configure' do
    Datadog::Configurable.keys.each do |key|
      it "sets the #{key.to_s.gsub('_', ' ')}" do
        Datadog.configure do |config|
          config.send("#{key}=", key)
        end
        expect(Datadog.instance_variable_get(:"@#{key}")).to eq(key)
      end
    end
  end
end
