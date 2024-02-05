# frozen_string_literal: true

require_relative '../src/main'

RSpec.describe Main do
  let(:client_double) { instance_double(Client) }
  let(:client_response) { 'Hello world' }
  let(:chat_config_double) { instance_double(ChatConfig) }
  let(:tiktoken_double) { instance_double(Tiktoken::Encoding) }

  before do
    allow(Client).to receive(:new).and_return(client_double)
    allow(client_double).to receive_messages(request: client_response, model: 'model')

    allow(ChatConfig).to receive(:new).and_return(chat_config_double)
    allow(chat_config_double).to receive_messages(model_profile: '', history_messages: [], temperature: 1.0,
                                                  configure!: nil)
    allow(Tiktoken).to receive(:encoding_for_model).and_return(tiktoken_double)
    allow(tiktoken_double).to receive(:encode).and_return('')
  end

  describe 'initialize' do
    it 'does not raise error' do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe 'chat!' do
    let(:expected) do
      [
        { content: '', role: 'system' },
        { content: 'foobar', role: 'user' },
        { content: 'Hello world', role: 'assistant' }
      ]
    end

    before do
      allow(Chat)
        .to receive(:read_user_input)
        .and_return({ command_executed: false, user_content: 'foobar' })
    end

    it 'does not raise error' do
      main = described_class.new
      expect { main.chat! }.not_to raise_error
    end

    it 'updates history' do
      main = described_class.new
      main.chat!
      expect(main.messages).to eq(expected)
    end

    describe 'when error raised' do
      it 'dumps history' do
        allow(Chat).to receive(:read_user_input).and_raise(StandardError)
        allow(Chat).to receive(:dump_message).and_return(nil)

        main = described_class.new
        main.chat!
        expect(Chat).to have_received(:dump_message)
      end
    end
  end
end
